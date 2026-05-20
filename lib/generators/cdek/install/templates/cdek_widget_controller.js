import { Controller } from "@hotwired/stimulus"

// Stimulus-контроллер виджета ПВЗ СДЭК.
//
// КРИТИЧНО: @cdek-it/widget@3 (UMD) ожидает параметр `root` как СТРОКОВЫЙ
// ID DOM-элемента, не как сам DOM-объект. Внутри виджет вызывает
// `document.getElementById(params.root)`. Если передать туда HTMLElement —
// getElementById вернёт null, и виджет создаст «висячий» div в памяти,
// продолжит делать запросы офисов (мы это видим в server-логах), но в
// видимом DOM нашего root-таргета ничего не отрисует. Поэтому здесь мы
// гарантируем, что у root-элемента есть уникальный id, и передаём
// виджету именно строку.

let _scriptPromise = null

function ensureWidgetScript(url) {
    if (typeof window.CDEKWidget !== "undefined") {
        return Promise.resolve()
    }
    if (_scriptPromise) return _scriptPromise
    _scriptPromise = new Promise((resolve, reject) => {
        const s = document.createElement("script")
        s.src = url
        s.async = true
        s.onload = () => resolve()
        s.onerror = () => { _scriptPromise = null; reject(new Error("Не удалось загрузить скрипт виджета СДЭК")) }
        document.head.appendChild(s)
    })
    return _scriptPromise
}

function setFieldValue(id, value) {
    if (!id) return
    const el = document.getElementById(id)
    if (el) {
        el.value = value == null ? "" : String(value)
        el.dispatchEvent(new Event("change", { bubbles: true }))
    }
}

function setText(selector, value) {
    if (!selector) return
    document.querySelectorAll(selector).forEach((el) => { el.textContent = value })
}

export default class extends Controller {
    static targets = ["root", "error"]
    static values = {
        servicePath:     String,
        scriptUrl:       String,
        apiKey:          String,
        defaultLocation: { type: String, default: "Москва" },
        senderCity:      { type: String, default: "Москва" },
        modalId:         { type: String, default: "" },
        fieldCode:       { type: String, default: "order_cdek_point_code" },
        fieldName:       { type: String, default: "order_cdek_point_name" },
        fieldAddress:    { type: String, default: "order_cdek_point_address" },
        fieldCityCode:   { type: String, default: "order_cdek_city_code" },
        labelSelector:   { type: String, default: "[data-cdek-widget-label]" },
        addressSelector: { type: String, default: "#order_cdek_point_address_view" }
    }

    connect() {
        ensureWidgetScript(this.scriptUrlValue)
            .then(() => this._mountWidget())
            .catch((err) => this._showError(err && err.message ? err.message : "ошибка"))
    }

    disconnect() {
        if (this._widget) {
            try {
                if (typeof this._widget.destroy === "function") this._widget.destroy()
                else if (typeof this._widget.close === "function") this._widget.close()
            } catch (_) { /* no-op */ }
            this._widget = null
        }
    }

    _mountWidget() {
        if (!this.hasRootTarget) return
        if (typeof window.CDEKWidget !== "function") {
            this._showError("CDEKWidget недоступен после загрузки скрипта")
            return
        }

        // Гарантируем уникальный DOM-id у root'а и передаём его виджету строкой.
        if (!this.rootTarget.id) {
            this.rootTarget.id = "cdek-widget-root-" + Math.random().toString(36).slice(2, 10)
        }

        try {
            this._widget = new window.CDEKWidget({
                root:                this.rootTarget.id,
                servicePath:         this.servicePathValue,
                apiKey:              this.apiKeyValue,
                defaultLocation:     this.defaultLocationValue,
                from:                { address: this.senderCityValue },
                goods:               [{ width: 30, height: 10, length: 30, weight: 1 }],
                tariffs:             { office: [136, 234], door: [137, 233], pickup: [138, 235] },
                hideDeliveryOptions: { door: true, office: false },
                lang:                "rus",
                currency:            "RUB",
                onChoose:            (mode, tariff, office) => this._handleChoose(office)
            })
        } catch (err) {
            this._showError(err && err.message ? err.message : "ошибка инициализации виджета")
        }
    }

    _handleChoose(office) {
        if (!office) return
        const code     = office.code || ""
        const name     = office.name || ""
        const address  = (office.location && (office.location.address_full || office.location.address)) || ""
        const cityCode = (office.location && office.location.city_code) || ""

        setFieldValue(this.fieldCodeValue,     code)
        setFieldValue(this.fieldNameValue,     name)
        setFieldValue(this.fieldAddressValue,  address)
        setFieldValue(this.fieldCityCodeValue, cityCode)

        const label = name ? (code ? `${name} (${code})` : name) : "не выбран"
        setText(this.labelSelectorValue,   label)
        setText(this.addressSelectorValue, address)

        this.dispatch("chosen", { detail: { office } })
        if (this.modalIdValue) {
            document.dispatchEvent(new CustomEvent("modal:close", { detail: { id: this.modalIdValue } }))
        }
    }

    _showError(message) {
        if (this.hasErrorTarget) {
            this.errorTarget.textContent = `Не удалось открыть виджет СДЭК: ${message}.`
            this.errorTarget.style.display = ""
        }
        if (this.hasRootTarget) {
            this.rootTarget.style.display = "none"
        }
    }
}
