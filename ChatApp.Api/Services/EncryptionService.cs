using System.Security.Cryptography;
using System.Text;

namespace ChatApp.Api.Services // 🎯 CHỖ NÀY LÀ QUAN TRỌNG NHẤT NÈ: Phải có chữ .Api
{
    public class EncryptionService
    {
        private readonly byte[] _key;
        public string CurrentKeyId => "v1";

        public EncryptionService(IConfiguration config)
        {
            // Lấy Key 32-bytes từ appsettings.json
            var base64Key = config["Encryption:MessageKey"]; 
            
            if (string.IsNullOrEmpty(base64Key))
            {
                throw new ArgumentNullException("Encryption:MessageKey", "Chưa cấu hình Key mã hóa trong appsettings.json!");
            }

            _key = Convert.FromBase64String(base64Key);
        }

        public (string Ciphertext, string Nonce, string Tag) Encrypt(string plaintext)
        {
            using var aes = new AesGcm(_key, tagSizeInBytes: 16);
            var nonce = new byte[12];
            RandomNumberGenerator.Fill(nonce);

            var plaintextBytes = Encoding.UTF8.GetBytes(plaintext);
            var ciphertextBytes = new byte[plaintextBytes.Length];
            var tagBytes = new byte[16];

            aes.Encrypt(nonce, plaintextBytes, ciphertextBytes, tagBytes);

            return (
                Convert.ToBase64String(ciphertextBytes),
                Convert.ToBase64String(nonce),
                Convert.ToBase64String(tagBytes)
            );
        }

        public string Decrypt(string ciphertext, string nonce, string tag)
        {
            using var aes = new AesGcm(_key, tagSizeInBytes: 16);
            var ciphertextBytes = Convert.FromBase64String(ciphertext);
            var nonceBytes = Convert.FromBase64String(nonce);
            var tagBytes = Convert.FromBase64String(tag);
            
            var decryptedBytes = new byte[ciphertextBytes.Length];
            aes.Decrypt(nonceBytes, ciphertextBytes, tagBytes, decryptedBytes);

            return Encoding.UTF8.GetString(decryptedBytes);
        }
    }
}