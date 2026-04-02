import Foundation

enum AppConfig {
    static var supabaseURL: String? {
        stringValue(forKeys: ["SUPABASE_URL", "SupabaseURL", "supabase_url"]) ?? fallbackSupabaseURL
    }

    static var supabaseAnonKey: String? {
        stringValue(forKeys: ["SUPABASE_ANON_KEY", "SupabaseAnonKey", "supabase_anon_key"]) ?? fallbackSupabaseAnonKey
    }

    static var supabaseEmailRedirectTo: String? {
        stringValue(forKeys: ["SUPABASE_EMAIL_REDIRECT_TO", "SupabaseEmailRedirectTo", "supabase_email_redirect_to"]) ?? fallbackEmailRedirectTo
    }

    private static func stringValue(forKeys keys: [String]) -> String? {
        for key in keys {
            if let fromBundle = Bundle.main.object(forInfoDictionaryKey: key) as? String {
                let cleaned = fromBundle.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty { return cleaned }
            }

            if let fromEnv = ProcessInfo.processInfo.environment[key] {
                let cleaned = fromEnv.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty { return cleaned }
            }
        }
        return nil
    }

    // School-project fallback values to keep auth working if Info.plist keys are not resolved.
    private static let fallbackSupabaseURL = "https://cyuamhemphmvbtquxali.supabase.co"
    private static let fallbackSupabaseAnonKey = "sb_publishable_YrmonVW1diK_jGB7rv3jgQ_Jl3eNor9"
    private static let fallbackEmailRedirectTo = "https://supabase.com"
}
