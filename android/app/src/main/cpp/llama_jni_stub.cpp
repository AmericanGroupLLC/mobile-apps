// Stub variant — used when vendor/llama.cpp submodule is missing so the
// Kotlin external functions still link. Returns canned echo strings.

#include <jni.h>
#include <android/log.h>
#include <string>

#define LOG_TAG "OfflineAIBuddy.JNI.Stub"
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)

extern "C" {

JNIEXPORT jlong JNICALL
Java_com_americangroupllc_offlineaibuddy_llm_LlamaJni_loadModelNative(
    JNIEnv* /* env */, jobject /* this */, jstring /* path */, jint /* ctx */) {
    LOGW("Stub JNI — vendor/llama.cpp submodule is not initialized.");
    return 0L;
}

JNIEXPORT void JNICALL
Java_com_americangroupllc_offlineaibuddy_llm_LlamaJni_unloadModelNative(
    JNIEnv* /* env */, jobject /* this */, jlong /* handle */) {
}

JNIEXPORT jstring JNICALL
Java_com_americangroupllc_offlineaibuddy_llm_LlamaJni_generateNative(
    JNIEnv* env, jobject /* this */, jlong /* handle */,
    jstring /* sys */, jstring userPrompt, jint /* maxTokens */) {
    const char* usr = env->GetStringUTFChars(userPrompt, nullptr);
    std::string out = "(stub) ";
    out += usr;
    env->ReleaseStringUTFChars(userPrompt, usr);
    return env->NewStringUTF(out.c_str());
}

}
