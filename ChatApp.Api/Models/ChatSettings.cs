namespace ChatApp.Api.Models
{
    public class ChatSettings
    {
        public bool MuteNotifications { get; set; } = false;
        public string ThemeColor { get; set; } = "default";
        public string? Nickname { get; set; } 
    }
}