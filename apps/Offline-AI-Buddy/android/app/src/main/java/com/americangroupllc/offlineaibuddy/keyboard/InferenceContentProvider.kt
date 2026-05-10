package com.americangroupllc.offlineaibuddy.keyboard

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri

/**
 * Exported (signature-permission protected) ContentProvider used as
 * the cross-process fallback for the IME → main-app inference call.
 *
 * In v1 the IME and main app share the same APK so they can call
 * LlamaService directly via Hilt — this provider is here for v1.1
 * when we may split them.
 */
class InferenceContentProvider : ContentProvider() {
    override fun onCreate(): Boolean = true
    override fun query(uri: Uri, p: Array<out String>?, s: String?, sa: Array<out String>?, o: String?): Cursor? {
        return MatrixCursor(arrayOf("suggestion"))
    }
    override fun getType(uri: Uri): String? = "vnd.android.cursor.dir/vnd.com.americangroupllc.offlineaibuddy.suggestion"
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int = 0
}
