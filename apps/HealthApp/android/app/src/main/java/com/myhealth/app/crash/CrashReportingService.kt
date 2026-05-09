package com.myhealth.app.crash

import android.content.Context
import android.content.SharedPreferences
import io.sentry.Sentry
import io.sentry.SentryLevel
import io.sentry.android.core.SentryAndroid

/**
 * Privacy-first wrapper around the Sentry Android SDK. Mirrors the iOS
 * `CrashReportingService` contract:
 *
 *   * Disabled by default. Only initializes when the user opts in via
 *     Settings -> "Send crash reports".
 *   * Reads the DSN from `BuildConfig.SENTRY_DSN` (injected at build time)
 *     OR from the `SENTRY_DSN` env var. No-op if neither is set.
 *   * Strips PII before send. Sample rate for transactions is 0.
 */
object CrashReportingService {

    private const val PREFS = "myhealth_crash"
    private const val KEY_ENABLED = "enabled"
    @Volatile private var started: Boolean = false

    fun isEnabled(context: Context): Boolean =
        prefs(context).getBoolean(KEY_ENABLED, false)

    fun setEnabled(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(KEY_ENABLED, enabled).apply()
        if (!enabled && started) {
            Sentry.close()
            started = false
        }
    }

    /** Call from Application.onCreate. No-op when disabled or DSN missing. */
    fun bootstrapIfEnabled(context: Context, releaseName: String,
                           environment: String = "production") {
        if (!isEnabled(context) || started) return
        val dsn = resolveDsn() ?: return
        SentryAndroid.init(context) { options ->
            options.dsn = dsn
            options.release = releaseName
            options.environment = environment
            options.tracesSampleRate = 0.0
            options.isAttachStacktrace = true
            options.isSendDefaultPii = false
            options.maxBreadcrumbs = 50
            options.beforeSend = io.sentry.SentryOptions.BeforeSendCallback { event, _ ->
                event.user = null  // strip any user-identifiable data
                event
            }
        }
        started = true
    }

    fun captureError(t: Throwable) {
        if (started) Sentry.captureException(t)
    }

    fun captureMessage(msg: String, level: SentryLevel = SentryLevel.INFO) {
        if (started) Sentry.captureMessage(msg, level)
    }

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun resolveDsn(): String? {
        // BuildConfig.SENTRY_DSN is injected by Gradle when the
        // SENTRY_DSN env var or local property is set; fall back to the
        // process env so dev runs work without a Gradle rebuild.
        val fromEnv = System.getenv("SENTRY_DSN")
        if (!fromEnv.isNullOrEmpty()) return fromEnv
        return try {
            val cls = Class.forName("com.myhealth.app.BuildConfig")
            val field = cls.getField("SENTRY_DSN")
            (field.get(null) as? String).takeIf { !it.isNullOrEmpty() }
        } catch (_: Throwable) { null }
    }
}
