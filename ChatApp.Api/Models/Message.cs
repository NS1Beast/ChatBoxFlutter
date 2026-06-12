using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json;

namespace ChatApp.Api.Models
{

    [Table("messages")] 
    public class Message
    {
        [Key]
        [Column("id")] 
        public Guid Id { get; set; } = Guid.NewGuid();
        
        [Column("conversationid")]
        public Guid ConversationId { get; set; }
        
        [Column("senderid")]
        public Guid? SenderId { get; set; }
        
     
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
        
        [Column("metadata", TypeName = "jsonb")]
        public JsonDocument? Metadata { get; set; }
        
        [Column("isdeleted")]
        public bool IsDeleted { get; set; } = false;
        
        [Column("createdat")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("ConversationId")]
        public Conversation? Conversation { get; set; }
        
        [ForeignKey("SenderId")]
        public User? Sender { get; set; }
    }
}