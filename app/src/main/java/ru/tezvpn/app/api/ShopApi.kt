package ru.tezvpn.app.api

import android.content.Context
import android.content.SharedPreferences
import okhttp3.Cookie
import okhttp3.CookieJar
import okhttp3.HttpUrl
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import ru.tezvpn.app.BuildConfig
import java.io.File
import java.io.IOException
import java.net.InetSocketAddress
import java.net.Proxy
import java.util.UUID
import java.util.concurrent.TimeUnit

class ShopApi(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("tez_shop", Context.MODE_PRIVATE)

    val deviceFp: String
        get() {
            var id = prefs.getString("fp", null)
            if (id.isNullOrBlank()) {
                id = UUID.randomUUID().toString().replace("-", "")
                prefs.edit().putString("fp", id).apply()
            }
            return id
        }

    private val cookieJar = object : CookieJar {
        override fun saveFromResponse(url: HttpUrl, cookies: List<Cookie>) {
            val tez = cookies.firstOrNull { it.name == "tezweb" } ?: return
            prefs.edit().putString("cookie_value", tez.value).apply()
        }

        override fun loadForRequest(url: HttpUrl): List<Cookie> {
            val v = prefs.getString("cookie_value", null) ?: return emptyList()
            return listOf(
                Cookie.Builder()
                    .name("tezweb")
                    .value(v)
                    .domain(url.host)
                    .path("/")
                    .secure()
                    .build(),
            )
        }
    }

    private val client = OkHttpClient.Builder()
        .cookieJar(cookieJar)
        .connectTimeout(12, TimeUnit.SECONDS)
        .readTimeout(40, TimeUnit.SECONDS)
        .writeTimeout(40, TimeUnit.SECONDS)
        .build()

    /** BlueStacks leaves Windows VPN (Amnezia) and hits the blocked Wi-Fi path. */
    private val hostProxyClient = client.newBuilder()
        .proxy(Proxy(Proxy.Type.HTTP, InetSocketAddress("10.0.2.2", 18080)))
        .build()

    private fun request(path: String, method: String = "GET", json: String? = null): JSONObject {
        try {
            return execute(client, path, method, json)
        } catch (e: IOException) {
            if (!File("/mnt/windows").exists()) throw e
            return execute(hostProxyClient, path, method, json)
        }
    }

    private fun execute(http: OkHttpClient, path: String, method: String, json: String?): JSONObject {
        val builder = Request.Builder()
            .url(BuildConfig.SHOP_URL + path)
            .header("Accept", "application/json")
            .header("X-Tez-FP", deviceFp)
        if (json != null) {
            builder.method(method, json.toRequestBody(JSON))
        }
        http.newCall(builder.build()).execute().use { resp ->
            val text = resp.body?.string().orEmpty().trim().removePrefix("\uFEFF")
            val obj = if (text.startsWith("{")) JSONObject(text) else JSONObject()
            if (!resp.isSuccessful) {
                val err = obj.optString("error").ifBlank { "Ошибка ${resp.code}" }
                throw IllegalStateException(err)
            }
            if (!text.startsWith("{")) {
                throw IllegalStateException("Сервер ответил не JSON")
            }
            return obj
        }
    }

    fun state(): ShopState = parseState(request("/api/state"))

    fun startOrder(planId: String): ShopState {
        val body = JSONObject().put("plan", planId).toString()
        val obj = request("/api/order", "POST", body)
        return parseState(obj)
    }

    fun setName(name: String): ShopState {
        val body = JSONObject().put("name", name).toString()
        val obj = request("/api/name", "POST", body)
        return parseState(obj)
    }

    fun uploadReceipt(bytes: ByteArray, filename: String): ShopState {
        val fileBody = bytes.toRequestBody(
            if (filename.endsWith(".pdf", true)) "application/pdf".toMediaType()
            else "image/jpeg".toMediaType(),
        )
        val multipart = MultipartBody.Builder().setType(MultipartBody.FORM)
            .addFormDataPart("file", filename, fileBody)
            .build()
        val req = Request.Builder()
            .url(BuildConfig.SHOP_URL + "/api/receipt")
            .header("X-Tez-FP", deviceFp)
            .post(multipart)
            .build()
        try {
            return postReceipt(client, req)
        } catch (e: IOException) {
            if (!File("/mnt/windows").exists()) throw e
            return postReceipt(hostProxyClient, req)
        }
    }

    private fun postReceipt(http: OkHttpClient, req: Request): ShopState {
        http.newCall(req).execute().use { resp ->
            val text = resp.body?.string().orEmpty().trim().removePrefix("\uFEFF")
            val obj = if (text.startsWith("{")) JSONObject(text) else JSONObject()
            if (!resp.isSuccessful) {
                throw IllegalStateException(obj.optString("error").ifBlank { "Не удалось отправить чек" })
            }
            if (!text.startsWith("{")) throw IllegalStateException("Сервер ответил не JSON")
            return parseState(obj)
        }
    }

    fun loadConfig(oid: String): VpnConfig? {
        val obj = request("/api/config?oid=$oid")
        return parseConfig(obj.optJSONObject("config"))
    }

    fun login(code: String): ShopState {
        val body = JSONObject().put("code", code).toString()
        request("/api/login", "POST", body)
        return state()
    }

    companion object {
        private val JSON = "application/json; charset=utf-8".toMediaType()

        fun parseState(obj: JSONObject): ShopState {
            val plans = obj.optJSONArray("plans").orEmpty().mapNotNull { it.toPlan() }
            val orders = obj.optJSONArray("orders").orEmpty().mapNotNull { it.toOrder() }
            val order = obj.optJSONObject("order")?.toOrder()
            return ShopState(
                plans = plans,
                pay = obj.optJSONObject("pay").toPay(),
                order = order,
                orders = orders.ifEmpty { listOfNotNull(order) },
                config = parseConfig(obj.optJSONObject("config")),
                account = obj.optJSONObject("account")?.let {
                    Account(it.optString("code"))
                },
                meta = obj.optJSONObject("meta").toMeta(),
                flash = obj.optString("flash").ifBlank { null },
            )
        }

        private fun parseConfig(obj: JSONObject?): VpnConfig? {
            if (obj == null) return null
            val devices = obj.optJSONArray("devices").orEmpty().mapNotNull { d ->
                val conf = d.optString("conf")
                if (conf.isBlank()) null
                else VpnDevice(
                    name = d.optString("name"),
                    conf = conf,
                    vpnuri = d.optString("vpnuri"),
                )
            }
            if (devices.isEmpty()) return null
            return VpnConfig(sid = obj.optString("sid"), devices = devices)
        }

        private fun JSONObject?.toPay(): PayInfo {
            if (this == null) return PayInfo()
            return PayInfo(
                alif = optString("alif"),
                dc = optString("dc"),
                payee = optString("payee"),
                support = optString("support"),
                wechat = optBoolean("wechat"),
                alipay = optBoolean("alipay"),
            )
        }

        private fun JSONObject?.toMeta(): Meta {
            if (this == null) return Meta()
            return Meta(
                title = optString("title").ifBlank { "TEZVPN" },
                bot = optString("bot").ifBlank { "teztezvpn_bot" },
                support = optString("support").ifBlank { "BarzuRizoev" },
            )
        }

        private fun JSONObject.toPlan(): Plan = Plan(
            id = optString("id"),
            title = optString("title"),
            tjs = optDouble("tjs", 0.0),
            cny = optDouble("cny", 0.0),
            devices = optInt("devices", 1),
            expires = optString("expires"),
        )

        private fun JSONObject.toOrder(): Order = Order(
            id = optString("id"),
            plan = optString("plan"),
            title = optString("title"),
            amount = opt("amount")?.toString().orEmpty().removeSuffix(".0"),
            status = optString("status"),
            statusLabel = optString("status_label"),
            name = optString("name"),
            ready = optBoolean("ready") || optString("status") == "fulfilled",
        )

        private fun JSONArray?.orEmpty(): List<JSONObject> {
            if (this == null) return emptyList()
            return (0 until length()).mapNotNull { i -> optJSONObject(i) }
        }
    }
}
