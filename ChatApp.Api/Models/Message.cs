using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json;

namespace ChatApp.Api.Models
{
    public class Message
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        
        public Guid ConversationId { get; set; }
        
        public Guid? SenderId { get; set; } // Nullable nếu user bị xóa
        
        // 🎯 CÁC CỘT ĐÃ ĐƯỢC CẬP NHẬT ĐỂ MÃ HÓA AES-GCM
        public string Ciphertext { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string Nonce { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string Tag { get; set; } = string.Empty;
        
        [MaxLength(50)]
        public string KeyId { get; set; } = "v1";

        [MaxLength(20)]
        public string Type { get; set; } = "text";
        
        // Nếu dùng JSONB trong PostgreSQL, EF Core có thể map nó với JsonDocument hoặc string
        [Column(TypeName = "jsonb")]
        public JsonDocument? Metadata { get; set; }
        
        public bool IsDeleted { get; set; } = false;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("ConversationId")]
        public Conversation? Conversation { get; set; }
        
        [ForeignKey("SenderId")]
        public User? Sender { get; set; }
    }
}