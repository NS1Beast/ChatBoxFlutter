using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ChatApp.Api.Models
{
    public class Participant
    {
  
        public Guid ConversationId { get; set; }
        
        public Guid UserId { get; set; }
        
        [MaxLength(20)]
        public string Role { get; set; } = "member";
        
        public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
        
        public Guid? LastReadMessageId { get; set; }

        // Navigation properties (Tùy chọn)
        [ForeignKey("ConversationId")]
        public Conversation? Conversation { get; set; }
        
        [ForeignKey("UserId")]
        public User? User { get; set; }
    }
}