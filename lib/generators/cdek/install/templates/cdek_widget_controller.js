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
//
// Про from / sender_city_code:
// Если в `from` передавать только { address: "Москва" }, CDEK API не
// возвращает склад-склад тарифы (только дверь-*), и виджет показывает
// «Выберите тариф». Чтобы получить полный набор тарифов, нужно передать
// CDEK-код города отправителя (см. справочник /location/cities). Если код
// задан через data-cdek-widget-sender-city-code-value — используем его,
// иначе fallback на address.
//
// Про goods:
// CDEK считает тарифы по габаритам и весу отправления. Значение `goods`
// должно приходить от хост-приложения через data-cdek-widget-goods-value.
// Если массив не передан или невалиден, не подставляем статичные габариты:
// виджет будет открыт без расчётных packages, чтобы не считать доставку
// по выдуманным размерам.

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

function parseGoods(rawJson) {
    const trimmed = (rawJson || "").trim()
    if (trimmed === "") return []
    try {
        const parsed = JSON.parse(trimmed)
        if (Array.isArray(parsed)) return parsed
        return []
    } catch (_) {
        return []
    }
}

export default class extends Controller {
    static targets = ["root", "error"]
    static values = {
        servicePath:     String,
        scriptUrl:       String,
        apiKey:          String,
        defaultLocation: { type: String, default: "Москва" },
        senderCity:      { type: String, default: "Москва" },
        senderCityCode:  { type: String, default: "" },
        goods:           { type: String, default: "" },
        modalId:         { type: String, default: "" },
        fieldCode:       { type: String, default: "order_cdek_point_code" },
        fieldName:       { type: String, default: "order_cdek_point_name" },
        fieldAddress:    { type: String, default: "order_cdek_point_address" },
        fieldCityCode:   { type: String, default: "order_cdek_city_code" },
        labelSelector:   { type: String, default: "[data-cdek-widget-label]" },
        addressSelector: { type: String, default: "#order_cdek_point_address_view" }
    }

    connect() {
        this._connected = true
        this._mountWhenReady()
    }

    disconnect() {
        this._connected = false
        if (this._mountTimer) {
            window.clearTimeout(this._mountTimer)
            this._mountTimer = null
        }
        if (this._widget) {
            try {
                if (typeof this._widget.destroy === "function") this._widget.destroy()
                else if (typeof this._widget.close === "function") this._widget.close()
            } catch (_) { /* no-op */ }
            this._widget = null
        }
    }

    _mountWhenReady() {
        if (!this._connected || this._widget || this._mounting) return
        if (!this._isRootVisible()) {
            this._mountTimer = window.setTimeout(() => this._mountWhenReady(), 50)
            return
        }

        this._mounting = true
        ensureWidgetScript(this.scriptUrlValue)
            .then(() => this._mountWidget())
            .catch((err) => this._showError(err && err.message ? err.message : "ошибка"))
            .finally(() => { this._mounting = false })
    }

    _isRootVisible() {
        if (!this.hasRootTarget) return false
        const rect = this.rootTarget.getBoundingClientRect()
        return rect.width > 0 && rect.height > 0
    }

    _servicePath() {
        const url = new URL(this.servicePathValue, window.location.origin)
        const widgetCity = this.defaultLocationValue.trim()
        if (widgetCity !== "") {
            url.searchParams.set("widget_city", widgetCity)
        }
        return url.pathname + url.search
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

        // Если задан CDEK-код города отправителя — передаём его, иначе fallback
        // на address. С code CDEK вернёт склад-склад тарифы; с одним address —
        // только дверь-* (тогда виджет покажет "Выберите тариф" для офиса).
        const senderCodeRaw = this.senderCityCodeValue.trim()
        const senderCodeNum = senderCodeRaw === "" ? null : Number(senderCodeRaw)
        const from = (senderCodeNum !== null && Number.isFinite(senderCodeNum))
            ? { code: senderCodeNum }
            : { address: this.senderCityValue }

        const goods = parseGoods(this.goodsValue)
        const widgetOptions = {
            root:                this.rootTarget.id,
            servicePath:         this._servicePath(),
            apiKey:              this.apiKeyValue,
            defaultLocation:     this.defaultLocationValue,
            from:                from,
            hideDeliveryOptions: { door: true, office: false },
            lang:                "rus",
            currency:            "RUB",
            onChoose:            (mode, tariff, office) => this._handleChoose(office)
        }

        if (goods.length > 0) {
            widgetOptions.goods = goods
        }

        try {
            this._widget = new window.CDEKWidget(widgetOptions)
        } catch (err) {
            this._showError(err && err.message ? err.message : "ошибка инициализации виджета")
        }
    }

    _handleChoose(office) {
        if (!office) return
        const code     = office.code || ""
        const name     = office.name || ""
        const address  = office.address || office.address_full || ""
        const cityCode = office.city_code || ""

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
