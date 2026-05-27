using System;
using System.Collections.Generic;

namespace ChatApp.Api.Models;

public partial class Participant
{
    public Guid Conversationid { get; set; }

    public Guid Userid { get; set; }

    public string? Role { get; set; }

    public DateTime? Joinedat { get; set; }

    public Guid? Lastreadmessageid { get; set; }

    public virtual Conversation Conversation { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
