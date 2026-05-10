// JNI bridge into llama.cpp. Implementation outline only — wires up the
// Kotlin LlamaJni external function names. The real prompt-eval +
// sampling loop lives in the function bodies; we keep the surface small
// so the LlamaJni Kotlin side remains the single source of truth.

#include <jni.h>
#include <android/log.h>
#include <string>

#define LOG_TAG "OfflineAIBuddy.JNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

extern "C" {

JNIEXPORT jlong JNICALL
Java_com_americangroupllc_offlineaibuddy_llm_LlamaJni_loadModelNative(
    JNIEnv* env, jobject /* this */, jstring path, jint contextSize) {
    const char* cpath = env->GetStringUTFChars(path, nullptr);
    LOGI("loadModelNative path=%s ctx=%d", cpath, contextSize);
    env->ReleaseStringUTFChars(path, cpath);
    // Real impl: llama_backend_init(); model = llama_load_model_from_file(...);
    // Returns an opaque handle. For Phase 9 scaffolding this returns 0.
    return 0L;
}

JNIEXPORT void JNICALL
Java_com_americangroupllc_offlineaibuddy_llm_LlamaJni_unloadModelNative(
    JNIEnv* /* env */, jobject /* this */, jlong handle) {
    LOGI("unloadModelNative handle=%lld", (long long) handle);
    // Real impl: llama_free(handle); llama_backend_free();
}

JNIEXPORT jstring JNICALL
Java_com_americangroupllc_offlineaibuddy_llm_LlamaJni_generateNative(
    JNIEnv* env, jobject /* this */, jlong handle,
    jstring systemPrompt, jstring userPrompt, jint maxTokens) {
    const char* sys = env->GetStringUTFChars(systemPrompt, nullptr);
    const char* usr = env->GetStringUTFChars(userPrompt, nullptr);
    LOGI("generateNative handle=%lld maxTokens=%d", (long long) handle, maxTokens);
    std::string echo = "(jni-stub) ";
    echo += usr;
    env->ReleaseStringUTFChars(systemPrompt, sys);
    env->ReleaseStringUTFChars(userPrompt, usr);
    return env->NewStringUTF(echo.c_str());
}

}
