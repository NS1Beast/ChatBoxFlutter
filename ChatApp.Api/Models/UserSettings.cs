namespace ChatApp.Api.Models
{
    // Đại diện cho cục JSON trong bảng Users
    public class UserSettings
    {
        public string Theme { get; set; } = "light";
        public bool Notifications { get; set; } = true;
        public bool AutoDownload { get; set; } = true;
    }
}