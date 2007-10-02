/****** Object:  Table [dbo].[T_Campaign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Campaign](
	[Campaign_Num] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CM_Project_Num] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CM_Proj_Mgr_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_PI_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_comment] [varchar](500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_created] [datetime] NOT NULL,
	[Campaign_ID] [int] IDENTITY(2100,1) NOT NULL,
 CONSTRAINT [PK_T_Campaign] PRIMARY KEY NONCLUSTERED 
(
	[Campaign_ID] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Campaign_Campaign_Num] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Campaign_Campaign_Num] ON [dbo].[T_Campaign] 
(
	[Campaign_Num] ASC
) ON [PRIMARY]
GO

/****** Object:  Trigger [dbo].[trig_d_Campaign] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_d_Campaign] on [dbo].[T_Campaign]
For Delete
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the deleted Campaign
**
**	Auth:	mem
**	Date:	10/02/2007 mem - Initial version (Ticket #543)
**    
*****************************************************/
AS
	-- Add entries to T_Event_Log for each Campaign deleted from T_Campaign
	INSERT INTO T_Event_Log
		(
			Target_Type, 
			Target_ID, 
			Target_State, 
			Prev_Target_State, 
			Entered,
			Entered_By
		)
	SELECT	1 AS Target_Type, 
			Campaign_ID AS Target_ID, 
			0 AS Target_State, 
			1 AS Prev_Target_State, 
			GETDATE(), 
			suser_sname() + '; ' + IsNull(deleted.Campaign_Num, '??')
	FROM deleted
	ORDER BY Campaign_ID

GO

/****** Object:  Trigger [dbo].[trig_i_Campaign] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_i_Campaign] on [dbo].[T_Campaign]
For Insert
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the new Campaign
**
**	Auth:	mem
**	Date:	10/02/2007 mem - Initial version (Ticket #543)
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
	SELECT 1, inserted.Campaign_ID, 1, 0, GetDate()
	FROM inserted
	ORDER BY inserted.Campaign_ID

GO
GRANT SELECT ON [dbo].[T_Campaign] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Campaign] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Campaign] ([Campaign_Num]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Campaign] ([Campaign_Num]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Campaign] ([CM_Project_Num]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Campaign] ([CM_Project_Num]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Campaign] ([CM_Proj_Mgr_PRN]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Campaign] ([CM_Proj_Mgr_PRN]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Campaign] ([CM_PI_PRN]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Campaign] ([CM_PI_PRN]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Campaign] ([CM_comment]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Campaign] ([CM_comment]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Campaign] ([CM_created]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Campaign] ([CM_created]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Campaign] ([Campaign_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Campaign] ([Campaign_ID]) TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Campaign]  WITH CHECK ADD  CONSTRAINT [FK_T_Campaign_T_Users] FOREIGN KEY([CM_PI_PRN])
REFERENCES [T_Users] ([U_PRN])
GO
