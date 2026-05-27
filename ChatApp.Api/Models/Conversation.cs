using System;
using System.Collections.Generic;

namespace ChatApp.Api.Models;

public partial class Conversation
{
    public Guid Id { get; set; }

    public bool? Isgroup { get; set; }

    public string? Groupname { get; set; }

    public string? Groupavatarurl { get; set; }

    public DateTime? Createdat { get; set; }

    public virtual ICollection<Message> Messages { get; set; } = new List<Message>();

    public virtual ICollection<Participant> Participants { get; set; } = new List<Participant>();
}
