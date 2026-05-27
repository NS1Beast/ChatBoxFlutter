using System;
using System.Collections.Generic;

namespace ChatApp.Api.Models;

public partial class Message
{
    public Guid Id { get; set; }

    public Guid? Conversationid { get; set; }

    public Guid? Senderid { get; set; }

    public string? Content { get; set; }

    public string? Type { get; set; }

    public string? Metadata { get; set; }

    public bool? Isdeleted { get; set; }

    public DateTime? Createdat { get; set; }

    public virtual Conversation? Conversation { get; set; }

    public virtual User? Sender { get; set; }
}
