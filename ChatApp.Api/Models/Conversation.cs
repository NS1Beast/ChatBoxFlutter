using System.ComponentModel.DataAnnotations;

namespace ChatApp.Api.Models
{
    public class Conversation
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        
        public bool IsGroup { get; set; } = false;
        
        [MaxLength(100)]
        public string? GroupName { get; set; }
        
        public string? GroupAvatarUrl { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties (Tùy chọn)
        public ICollection<Participant>? Participants { get; set; }
        public ICollection<Message>? Messages { get; set; }
    }
}