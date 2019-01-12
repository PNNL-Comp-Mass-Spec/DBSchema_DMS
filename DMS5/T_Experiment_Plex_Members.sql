/****** Object:  Table [dbo].[T_Experiment_Plex_Members] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Experiment_Plex_Members](
	[Plex_Exp_ID] [int] NOT NULL,
	[Channel] [tinyint] NOT NULL,
	[Exp_ID] [int] NOT NULL,
	[Channel_Type_ID] [tinyint] NOT NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Experiment_Plex_Members] PRIMARY KEY CLUSTERED 
(
	[Plex_Exp_ID] ASC,
	[Channel] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_T_Experiment_Plex_Members_Exp_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Experiment_Plex_Members_Exp_ID] ON [dbo].[T_Experiment_Plex_Members]
(
	[Exp_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members] ADD  CONSTRAINT [DF_T_Experiment_Plex_Members_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Plex_Members_T_Experiment_Plex_Channel_Type_Name] FOREIGN KEY([Channel_Type_ID])
REFERENCES [dbo].[T_Experiment_Plex_Channel_Type_Name] ([Channel_Type_ID])
GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members] CHECK CONSTRAINT [FK_T_Experiment_Plex_Members_T_Experiment_Plex_Channel_Type_Name]
GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Plex_Members_T_Experiments_Channel_Exp] FOREIGN KEY([Exp_ID])
REFERENCES [dbo].[T_Experiments] ([Exp_ID])
GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members] CHECK CONSTRAINT [FK_T_Experiment_Plex_Members_T_Experiments_Channel_Exp]
GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Plex_Members_T_Experiments_Plex_Exp] FOREIGN KEY([Plex_Exp_ID])
REFERENCES [dbo].[T_Experiments] ([Exp_ID])
GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members] CHECK CONSTRAINT [FK_T_Experiment_Plex_Members_T_Experiments_Plex_Exp]
GO
/****** Object:  Trigger [dbo].[trig_d_Experiment_Plex_Members] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_d_Experiment_Plex_Members] on [dbo].[T_Experiment_Plex_Members]
For Delete
/****************************************************
**
**  Desc:   Makes an entry in T_Experiment_Plex_Members_History for the deleted Exp_ID to Plex_Exp_ID mapping
**
**  Auth:   mem
**  Date:   11/28/2018 mem - Initial version
**    
*****************************************************/
AS
    Set NoCount On

    -- Add entries to T_Experiment_Plex_Members_History for each mapping deleted from T_Experiment_Plex_Members
    INSERT INTO T_Experiment_Plex_Members_History
        (
            Plex_Exp_ID, 
            Channel, 
            Exp_ID, 
            [State],
            Entered,
            Entered_By
        )
    SELECT  Plex_Exp_ID,
            Channel,
            Exp_Id,
            0 As [State], 
            GETDATE(), 
            suser_sname()
    FROM deleted
    ORDER BY Exp_ID, Channel

GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members] ENABLE TRIGGER [trig_d_Experiment_Plex_Members]
GO
/****** Object:  Trigger [dbo].[trig_i_Experiment_Plex_Members] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_i_Experiment_Plex_Members] on [dbo].[T_Experiment_Plex_Members]
For Insert
/****************************************************
**
**  Desc:  Makes an entry in T_Experiment_Plex_Members_History for the deleted Exp_ID to Plex_Exp_ID mapping
**
**  Auth:   mem
**  Date:   11/28/2018 mem - Initial version
**    
*****************************************************/
AS
    If @@RowCount = 0
        Return

    Set NoCount On

    -- Add entries to T_Experiment_Plex_Members_History for each mapping deleted from T_Experiment_Plex_Members
    INSERT INTO T_Experiment_Plex_Members_History
        (
            Plex_Exp_ID, 
            Channel, 
            Exp_ID, 
            [State],
            Entered,
            Entered_By
        )
    SELECT  Plex_Exp_ID,
            Channel,
            Exp_Id,
            1 As [State], 
            GETDATE(), 
            suser_sname()
    FROM inserted
    ORDER BY Plex_Exp_ID, Channel


GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members] ENABLE TRIGGER [trig_i_Experiment_Plex_Members]
GO
/****** Object:  Trigger [dbo].[trig_u_Experiment_Plex_Members] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_u_Experiment_Plex_Members] on [dbo].[T_Experiment_Plex_Members]
For Update
/****************************************************
**
**  Desc:  Makes an entry in T_Experiment_Plex_Members_History for the updated Exp_ID to Plex_Exp_ID mappings
**
**  Auth:   mem
**  Date:   11/28/2018 mem - Initial version
**    
*****************************************************/
AS
    If @@RowCount = 0
        Return

    Set NoCount On

    If Update(Exp_ID)
    Begin
        -- Add entries to T_Experiment_Plex_Members_History for each mapping changed in T_Experiment_Plex_Members
        INSERT INTO T_Experiment_Plex_Members_History
            (
                Plex_Exp_ID, 
                Channel, 
                Exp_ID, 
                [State],
                Entered,
                Entered_By
            )
        SELECT deleted.Plex_Exp_ID,
               deleted.Channel,
               deleted.Exp_Id,
               0 AS [State],
               GETDATE(),
               suser_sname()
        FROM inserted
             INNER JOIN deleted
               ON inserted.Plex_Exp_ID = deleted.Plex_Exp_ID AND
                  inserted.Channel = deleted.Channel AND
                  inserted.Exp_id <> deleted.Exp_id
        ORDER BY deleted.Plex_Exp_ID, deleted.Channel

        INSERT INTO T_Experiment_Plex_Members_History
            (
                Plex_Exp_ID, 
                Channel, 
                Exp_ID, 
                [State],
                Entered,
                Entered_By
            )
        SELECT inserted.Plex_Exp_ID,
               inserted.Channel,
               inserted.Exp_Id,
               1 AS [State],
               GETDATE(),
               suser_sname()
        FROM inserted
             INNER JOIN deleted
               ON inserted.Plex_Exp_ID = deleted.Plex_Exp_ID AND
                  inserted.Channel = deleted.Channel AND
                  inserted.Exp_id <> deleted.Exp_id
        ORDER BY inserted.Plex_Exp_ID, inserted.Channel

    End

GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members] ENABLE TRIGGER [trig_u_Experiment_Plex_Members]
GO
/****** Object:  Trigger [dbo].[trig_ud_T_Experiment_Plex_Members] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[trig_ud_T_Experiment_Plex_Members]
ON [dbo].[T_Experiment_Plex_Members]
FOR UPDATE, DELETE AS
/****************************************************
**
**  Desc:   Prevents updating or deleting all rows in the table
**
**  Auth:   mem
**  Date:   11/28/2018
**
*****************************************************/
BEGIN

    DECLARE @Count int
    SET @Count = @@ROWCOUNT;

    DECLARE @ExistingRows int=0
    SELECT @ExistingRows = i.rowcnt
    FROM dbo.sysobjects o INNER JOIN dbo.sysindexes i ON o.id = i.id
    WHERE o.name = 'T_Experiment_Plex_Members' AND o.type = 'u' AND i.indid < 2

    IF @Count > 0 AND @ExistingRows > 11 AND @Count >= @ExistingRows
    BEGIN

        RAISERROR('Cannot update or delete all rows. Use a WHERE clause (see trigger trig_ud_T_Experiment_Plex_Members)',16,1)
        ROLLBACK TRANSACTION
        RETURN;

    END

END

GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members] ENABLE TRIGGER [trig_ud_T_Experiment_Plex_Members]
GO
