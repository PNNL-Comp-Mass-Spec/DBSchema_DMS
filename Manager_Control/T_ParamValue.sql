/****** Object:  Table [dbo].[T_ParamValue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_ParamValue](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[TypeID] [int] NOT NULL,
	[Value] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[MgrID] [int] NOT NULL,
	[Comment] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Last_Affected] [datetime] NULL,
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_ParamValue] PRIMARY KEY NONCLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_ParamValue] ******/
CREATE UNIQUE CLUSTERED INDEX [IX_T_ParamValue] ON [dbo].[T_ParamValue] 
(
	[MgrID] ASC,
	[TypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_ParamValue_TypeID_Include_EntryID_MgrID] ******/
CREATE NONCLUSTERED INDEX [IX_T_ParamValue_TypeID_Include_EntryID_MgrID] ON [dbo].[T_ParamValue] 
(
	[TypeID] ASC
)
INCLUDE ( [Entry_ID],
[MgrID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Trigger [dbo].[trig_d_T_ParamValue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_d_T_ParamValue] ON [dbo].[T_ParamValue] 
FOR DELETE
AS
/****************************************************
**
**	Desc: 
**		Adds an entry to T_Event_Log if TypeID 17 (mgractive) is deleted
**
**	Auth:	mem
**	Date:	04/23/2008
**    
*****************************************************/
	
	Set NoCount On

	-- Add a new row to T_Event_Log
	INSERT INTO T_Event_Log( Target_Type,
	                         Target_ID,
	                         Target_State,
	                         Prev_Target_State )
	SELECT 1 AS Target_Type,
	       deleted.MgrID,
	       -1 AS Target_State,
	       CASE deleted.[Value]
	           WHEN 'True' THEN 1
	           ELSE 0
	       END AS Prev_Target_State
	FROM deleted
	WHERE deleted.TypeID = 17

GO
/****** Object:  Trigger [dbo].[trig_i_T_ParamValue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_i_T_ParamValue] ON [dbo].[T_ParamValue] 
FOR INSERT
AS
/****************************************************
**
**	Desc: 
**		Adds an entry to T_Event_Log if TypeID 17 (mgractive) is updated
**
**	Auth:	mem
**	Date:	04/23/2008
**			04/27/2009 mem - Removed If Update() tests since not required for an Insert trigger
**    
*****************************************************/
	
	If @@RowCount = 0
		Return

	IF EXISTS (SELECT * FROM inserted WHERE TypeID = 117)
		-- Add a new row to T_Event_Log
		INSERT INTO T_Event_Log( Target_Type,
								 Target_ID,
								 Target_State,
								 Prev_Target_State )
		SELECT 1, inserted.MgrID, 
				CASE inserted.[Value]
				WHEN 'True' THEN 1
				ELSE 0
				END AS Target_State,
				-1 AS Prev_Target_State
		FROM inserted
		WHERE inserted.TypeID = 117
		ORDER BY inserted.MgrID

GO
/****** Object:  Trigger [dbo].[trig_u_T_ParamValue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_u_T_ParamValue] ON [dbo].[T_ParamValue] 
FOR UPDATE
AS
/****************************************************
**
**	Desc: 
**		Updates Last_Affected and Entered_By if the parameter value changes
**		Adds an entry to T_Event_Log if TypeID 17 (mgractive) is updated
**
**		Note that the SYSTEM_USER and suser_sname() functions are equivalent, with
**		 both returning the username in the form PNL\D3L243 if logged in using 
**		 integrated authentication or returning the Sql Server login name if
**		 logged in with a Sql Server login
**
**	Auth:	mem
**	Date:	04/11/2008
**			04/23/2008 mem - Now adds an entry to T_Event_Log if the value for TypeID 17 (mgractive) changes
**    
*****************************************************/
	
	If @@RowCount = 0
		Return

	If	Update([TypeID]) OR
		Update([Value]) OR
		Update([MgrID])
	Begin
		-- Update the Last_Affected and Entered_By columns in T_ParamValue
		UPDATE T_ParamValue
		SET Last_Affected = GetDate(),
			Entered_By = SYSTEM_USER
		FROM T_ParamValue
			 INNER JOIN inserted
			   ON T_ParamValue.TypeID = inserted.TypeID AND
				  T_ParamValue.MgrID = inserted.MgrID

		-- Add a new row to T_Event_Log
		INSERT INTO T_Event_Log( Target_Type,
		                         Target_ID,
		                         Target_State,
		                         Prev_Target_State )
		SELECT 1 AS Target_Type,
		       inserted.MgrID,
		       CASE inserted.[Value]
		           WHEN 'True' THEN 1
		           ELSE 0
		       END AS Target_State,
		       CASE deleted.[Value]
		           WHEN 'True' THEN 1
		           ELSE 0
		       END AS Prev_Target_State
		FROM deleted
		     INNER JOIN inserted
		       ON deleted.MgrID = inserted.MgrID AND
		          deleted.TypeID = inserted.TypeID
		WHERE inserted.TypeID = 17

	End

GO
GRANT DELETE ON [dbo].[T_ParamValue] TO [PNL\D3m480] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_ParamValue] TO [PNL\D3m480] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_ParamValue] TO [PNL\D3m480] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_ParamValue] TO [PNL\D3m480] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_ParamValue] ([Last_Affected]) TO [DMSWebUser] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_ParamValue] ([Entered_By]) TO [DMSWebUser] AS [dbo]
GO
ALTER TABLE [dbo].[T_ParamValue]  WITH CHECK ADD  CONSTRAINT [FK_T_ParamValue_T_Mgrs] FOREIGN KEY([MgrID])
REFERENCES [T_Mgrs] ([M_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_ParamValue] CHECK CONSTRAINT [FK_T_ParamValue_T_Mgrs]
GO
ALTER TABLE [dbo].[T_ParamValue]  WITH CHECK ADD  CONSTRAINT [FK_T_ParamValue_T_ParamType] FOREIGN KEY([TypeID])
REFERENCES [T_ParamType] ([ParamID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_ParamValue] CHECK CONSTRAINT [FK_T_ParamValue_T_ParamType]
GO
ALTER TABLE [dbo].[T_ParamValue] ADD  CONSTRAINT [DF_T_ParamValue_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_ParamValue] ADD  CONSTRAINT [DF_T_ParamValue_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
