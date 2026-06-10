using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json;

namespace ChatApp.Api.Models
{
    // 🎯 Ép EF Core gọi đúng tên bảng chữ thường trong Postgres
    [Table("messages")] 
    public class Message
    {
        [Key]
        [Column("id")] // 🎯 Ép chữ thường cho khớp SQL
        public Guid Id { get; set; } = Guid.NewGuid();
        
        [Column("conversationid")]
        public Guid ConversationId { get; set; }
        
        [Column("senderid")]
        public Guid? SenderId { get; set; } // Nullable nếu user bị xóa
        
        // 🎯 CÁC CỘT MÃ HÓA AES-GCM
        [Column("ciphertext")]
        public string Ciphertext { get; set; } = string.Empty;
        
        [MaxLength(100)]
        [Column("nonce")]
        public string Nonce { get; set; } = string.Empty;
        
        [MaxLength(100)]
        [Column("tag")]
        public string Tag { get; set; } = string.Empty;
        
        [MaxLength(50)]
        [Column("keyid")]
        public string KeyId { get; set; } = "v1";

        [MaxLength(20)]
        [Column("type")]
        public string Type { get; set; } = "text";
        
        // Npgsql map jsonb hoàn hảo với JsonDocument
        [Column("metadata", TypeName = "jsonb")]
        public JsonDocument? Metadata { get; set; }
        
        [Column("isdeleted")]
        public bool IsDeleted { get; set; } = false;
        
        [Column("createdat")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // ==========================================
        // Navigation properties 
        // (Không cần map [Column] vì đây là Reference ảo của EF Core, không lưu xuống DB)
        // ==========================================
        [ForeignKey("ConversationId")]
        public Conversation? Conversation { get; set; }
        
        [ForeignKey("SenderId")]
        public User? Sender { get; set; }
    }
}