package com.americangroupllc.card.core.obs

interface CrashTransport {
    fun capture(throwable: Throwable)
    fun capture(message: String)
}

class CrashReportingService {
    var optedIn: Boolean = false
    private var transport: CrashTransport? = null

    fun attach(t: CrashTransport?) { transport = t }
    fun capture(t: Throwable) { if (optedIn) transport?.capture(t) }
    fun capture(msg: String)  { if (optedIn) transport?.capture(msg) }

    companion object { val shared = CrashReportingService() }
}
