package com.zexano.sms

object NormalizationEngine {

    /**
     * Returns true when [input] looks like a valid phone number that should
     * be normalised, and false when it should be treated as an alphanumeric
     * Sender ID or short code (e.g. "YT", "OTP", "111", "6060", "8000", "ZEXANO").
     *
     * Rules match Dart's NormalizationEngine identically:
     *   1. Contains ANY letter (Latin or Arabic) -> Sender ID
     *   2. After stripping +/0/spaces, fewer than 5 digits -> Sender ID
     *   3. Otherwise -> Phone number
     */
    fun isPhoneNumber(input: String): Boolean {
        if (input.isEmpty()) return false
        // Rule 1: any letter = Sender ID
        if (input.contains(Regex("[a-zA-Z\\u0600-\\u06ff]"))) return false

        // Rule 2: very short digit-only codes (e.g. 111, 6060, 8000)
        val digitsOnly = input.replace(Regex("[^0-9]"), "")
        if (digitsOnly.length < 5) return false

        return true
    }

    fun isSenderId(input: String): Boolean = !isPhoneNumber(input)

    /**
     * Normalizes a phone number to match Dart's NormalizationEngine.
     * Returns empty string if the input is a Sender ID or short code.
     */
    fun normalize(phone: String): String {
        val trimmed = phone.trim()
        if (trimmed.isEmpty() || isSenderId(trimmed)) return ""

        // Strip everything except digits and plus sign
        val cleaned = trimmed.replace(Regex("[^0-9+]"), "")
        if (cleaned.isEmpty()) return ""

        // Handle case where it already starts with +
        if (cleaned.startsWith("+")) {
            return cleaned
        }

        // International with 00
        if (cleaned.startsWith("00")) {
            return "+" + cleaned.substring(2)
        }

        // Remove leading zeros
        val noZeros = cleaned.replaceFirst(Regex("^0+"), "")

        // If it starts with 967, prepend +
        if (noZeros.startsWith("967")) {
            return "+$noZeros"
        }

        // Local Yemeni starting with 7
        if (noZeros.startsWith("7")) {
            return "+967$noZeros"
        }

        // Otherwise prepend +967
        return "+967$noZeros"
    }

    /**
     * Canonical generator for `peerId` used uniformly across
     * SQLite message_history, conversations, and UI routing.
     */
    fun generatePeerId(input: String): String {
        val trimmed = input.trim()
        if (trimmed.isEmpty()) return "sms:unknown"
        if (trimmed.startsWith("sms:")) return trimmed

        if (isSenderId(trimmed)) {
            val clean = trimmed.replace(Regex("\\s+"), "")
            return "sms:$clean"
        }

        val normalized = normalize(trimmed)
        if (normalized.isEmpty()) {
            val clean = trimmed.replace(Regex("\\s+"), "")
            return "sms:$clean"
        }
        return "sms:$normalized"
    }
}
