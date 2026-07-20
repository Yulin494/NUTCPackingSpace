import Foundation

/// `apps.nutc.edu.tw`（車位資料來源主機）的 TLS 設定有誤，
/// handshake 時只送出 leaf 憑證、漏了中繼憑證(TWCA SSL Certification Authority)，
/// 導致系統無法建立信任鏈而回報「憑證無效」。這裡內嵌該中繼憑證，
/// 在驗證時補進信任鏈，讓連線可以正常完成信任評估（而不是略過驗證）。
enum NUTCServerTrust {
    /// TWCA SSL Certification Authority（Base64 DER），簽發 apps.nutc.edu.tw 的憑證。
    private static let missingIntermediateBase64 = """
    MIIG1DCCBLygAwIBAgIQQAE0sE8AAAAAAAAAA+MkrDANBgkqhkiG9w0BAQwFADBQMQswCQYDVQQGEwJUVzESMBAGA1UEChMJVEFJ\
    V0FOLUNBMRAwDgYDVQQLEwdSb290IENBMRswGQYDVQQDExJUV0NBIENZQkVSIFJvb3QgQ0EwHhcNMjMwMjIzMDcyMjI0WhcNMzMw\
    MjIzMTU1OTU5WjBhMQswCQYDVQQGEwJUVzESMBAGA1UEChMJVEFJV0FOLUNBMRMwEQYDVQQLEwpTU0wgU3ViLUNBMSkwJwYDVQQD\
    EyBUV0NBIFNTTCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMquxiSlMrxf\
    OO29yqxCo/BIYBswnE7snZnuZDPcx8N9WhOdNGDsF024VjXKnXoVaZBcv56eFsU+w9Mcq+uIVYzjVrBoe5u8ZLE0hPSkluH8URhc\
    xtSQJ+gXcB0LJHsseAeXVcgqoxTSJ6/n0xTCeXEnGwSRAzrqTvjS2gbd3TILxsfIHwRgwwPjBDgmtjzbHHOFTJB3GCtH65T9A0vi\
    M2B/IW9Wz73jkz02AVMrZBHQ67IJ2W9CoIjd5mdGeIV36U9NXl+wZa/D90pLRsFVbItKgLXgF71CQ92vS/biTx8fA6UUCU2ToNcz\
    P5UrA/mDXCBCLakwa1I3ylRkgFwluJw9DqiYh56MRgsEABa+ZPrm1Qb9njQZK4Y4V+MLIvGM3xVoHIlvaSN29ubTueLpTeuAwN2V\
    TiRzfOyCRKTcMBCtlMw1WCJNAMiNWDWSBMnY9SlKv1oujmjS/ti0ptcipMymIoeWpVuQt3Mj8lYlKRpd6Zg8MbljMwQRSClK6O6M\
    SwpM3Xy5uJGh2cY5oYmKtxfyHSuKtKsk+daAPV1lpWYp9bNrbsLUPwmSY+zkVgkZdiWBF//RP/72/esANONINy5hkWjkVd0NLjA5\
    TAgk+DVVmnPtQIj1vBgtk8akY9CczIbEgKBonkHWn+GX2ycR6jadg2P+xrBFg4MGjomkb2gtAgMBAAGjggGXMIIBkzAfBgNVHSME\
    GDAWgBSdhWEUfMFib5do5E83QOGt4A1WNzAdBgNVHQ4EFgQU8ijU+dQcfhprFoLl75Mpae3KFSAwDgYDVR0PAQH/BAQDAgEGMBMG\
    A1UdJQQMMAoGCCsGAQUFBwMBMEoGA1UdIARDMEEwNQYLKwYBBAGCvyUBARUwJjAkBggrBgEFBQcCARYYaHR0cHM6Ly93d3cudHdj\
    YS5jb20udHcvMAgGBmeBDAECAjBNBgNVHR8ERjBEMEKgQKA+hjxodHRwOi8vUm9vdENBLnR3Y2EuY29tLnR3L1RXQ0FSQ0EvY3li\
    ZXJfcm9vdF9yZXZva2VfMjAyMi5jcmwwEgYDVR0TAQH/BAgwBgEB/wIBADB9BggrBgEFBQcBAQRxMG8wQwYIKwYBBQUHMAKGN2h0\
    dHA6Ly9zc2xzZXJ2ZXIudHdjYS5jb20udHcvY2FjZXJ0L2N5YmVyX3Jvb3RfMjAyMi5jcnQwKAYIKwYBBQUHMAGGHGh0dHA6Ly9y\
    b290b2NzcC50d2NhLmNvbS50dy8wDQYJKoZIhvcNAQEMBQADggIBAIFF/6Gnvu8L3xQDIampB8QVgoKS2bcjte0uJBbCrQHpzcGT\
    uVTkZaiA86LwVz6SAU7TVgVYRXmtx8l29WzfKI6wOAzmvlGZxSYAdN0I6YBkJK1nmDs0+TSw5lCzb+UOpajNOaMdJ5SNYTN87yRw\
    l82AFrwUmSLaMV4tN7W49N0SsELWs/d4uNHSMM0mBjd0hLDIWJFwOkuDyOWahnCVfPlCwSVWpUntOGgOHOA02IUE+JNX+spIV1Sw\
    AMYaEVyHe316YUgiGA5yk3liTa3vuv06eE1J2yiWrs9booW2VTHD+amzucFFNN1KvSLjSbYxG1t/FclHEN/y6hGM3bkjRC31A0jz\
    pv93D3MUQTdJascicPa0H4i8hviRriyetaC6HC4q8FQUTo2AcEpxicNGgyHhDV+YdbnS6GZL+f3bsmMM8ZFYZ77mDTS9mRO1VnIw\
    kjiN4vpzh67aKTpoD9TQzZcGQiJy6Pi+PCSFiqjK7UD/63L/Pt0hpoNKvZLrz4ngrlpyzpx8KjeSA5cjKcc6vlHm0Kk07k5djhJs\
    aqQELso5r+UXi9qC+nwqPuR/w5kJZv4fz0ND4UhY5y3qd+iCikkF3WzOzey7jUH9URKb3iZnRAHZvmyLK57UI0FwP+5xZEByvwXD\
    txbe914Hj3cSUrmKT3g/ZlOQQ1THeu48MA79
    """

    static let missingIntermediateCertificate: SecCertificate? = {
        guard let data = Data(base64Encoded: missingIntermediateBase64, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return SecCertificateCreateWithData(nil, data as CFData)
    }()
}

/// 提供給連線到 `nutc.edu.tw` 主機的 `URLSession` 使用，
/// 修補伺服器未送出完整憑證鏈時的信任評估（仍會完整驗證憑證，而非略過驗證）。
public final class NUTCServerTrustDelegate: NSObject, URLSessionDelegate {
    public override init() {}

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              challenge.protectionSpace.host.hasSuffix("nutc.edu.tw") else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if let intermediate = NUTCServerTrust.missingIntermediateCertificate {
            SecTrustSetAnchorCertificates(serverTrust, [intermediate] as CFArray)
            // 仍保留系統內建的根憑證清單，只是額外補上遺漏的中繼憑證。
            SecTrustSetAnchorCertificatesOnly(serverTrust, false)
        }

        if SecTrustEvaluateWithError(serverTrust, nil) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
