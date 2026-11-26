package com.gss.mediadownloader.export

import android.app.Activity
import android.content.Intent
import android.net.Uri
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException

/**
 * Save to Files on Android: SAF `ACTION_CREATE_DOCUMENT`, then a streamed copy
 * into the chosen document. The activity forwards [onActivityResult].
 */
class FileExporter(private val activity: Activity) : FileExportHostApi {
    private var pending: CompletableDeferred<Uri?>? = null

    override suspend fun exportFile(path: String, suggestedName: String, mimeType: String): Boolean {
        val source = File(path)
        if (!source.isFile) {
            throw IOException("File not found: $path")
        }
        // A second request while the picker is open cancels the first.
        pending?.complete(null)
        val result = CompletableDeferred<Uri?>().also { pending = it }
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            putExtra(Intent.EXTRA_TITLE, suggestedName)
        }
        activity.startActivityForResult(intent, REQUEST_CODE)
        val target = result.await() ?: return false

        withContext(Dispatchers.IO) {
            val output = activity.contentResolver.openOutputStream(target, "w")
                ?: throw IOException("Couldn't open the chosen file")
            output.use { out -> source.inputStream().use { input -> input.copyTo(out) } }
        }
        return true
    }

    /** Returns true when the result was the export picker's. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) {
            return false
        }
        val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
        pending?.complete(uri)
        pending = null
        return true
    }

    private companion object {
        const val REQUEST_CODE = 4107
    }
}
