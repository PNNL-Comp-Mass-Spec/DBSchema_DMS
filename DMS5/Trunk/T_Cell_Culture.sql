/****** Object:  Table [dbo].[T_Cell_Culture] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cell_Culture](
	[CC_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CC_Source_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CC_Owner_PRN] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CC_PI_PRN] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CC_Type] [int] NULL,
	[CC_Reason] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CC_Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CC_Campaign_ID] [int] NULL,
	[CC_ID] [int] IDENTITY(200,1) NOT NULL,
	[CC_Container_ID] [int] NOT NULL CONSTRAINT [DF_T_Cell_Culture_CC_Container_ID]  DEFAULT ((1)),
	[CC_Created] [datetime] NULL,
 CONSTRAINT [PK_T_Cell_Culture] PRIMARY KEY NONCLUSTERED 
(
	[CC_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Cell_Culture_CC_Campaign_ID] ******/
CREATE CLUSTERED INDEX [IX_T_Cell_Culture_CC_Campaign_ID] ON [dbo].[T_Cell_Culture] 
(
	[CC_Campaign_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Cell_Culture_CC_Created] ******/
CREATE NONCLUSTERED INDEX [IX_T_Cell_Culture_CC_Created] ON [dbo].[T_Cell_Culture] 
(
	[CC_Created] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Cell_Culture_CC_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Cell_Culture_CC_Name] ON [dbo].[T_Cell_Culture] 
(
	[CC_Name] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Cell_Culture_Container_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Cell_Culture_Container_ID] ON [dbo].[T_Cell_Culture] 
(
	[CC_Container_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Trigger [trig_d_Cell_Culture] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_d_Cell_Culture] on dbo.T_Cell_Culture
For Delete
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the deleted Cell Culture
**
**	Auth:	mem
**	Date:	10/02/2007 mem - Initial version (Ticket #543)
**			10/31/2007 mem - Added Set NoCount statement (Ticket #569)
**    
*****************************************************/
AS
	Set NoCount On

	-- Add entries to T_Event_Log for each Cell_Culture deleted from T_Cell_Culture
	INSERT INTO T_Event_Log
		(
			Target_Type, 
			Target_ID, 
			Target_State, 
			Prev_Target_State, 
			Entered,
			Entered_By
		)
	SELECT	2 AS Target_Type, 
			CC_ID AS Target_ID, 
			0 AS Target_State, 
			1 AS Prev_Target_State, 
			GETDATE(), 
			suser_sname() + '; ' + IsNull(deleted.CC_Name, '??')
	FROM deleted
	ORDER BY CC_ID

GO

/****** Object:  Trigger [trig_i_Cell_Culture] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_i_Cell_Culture] on dbo.T_Cell_Culture
For Insert
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the new Cell Culture
**
**	Auth:	mem
**	Date:	10/02/2007 mem - Initial version (Ticket #543)
**			10/31/2007 mem - Added Set NoCount statement (Ticket #569)
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
	SELECT 2, inserted.CC_ID, 1, 0, GetDate()
	FROM inserted
	ORDER BY inserted.CC_ID

GO
GRANT DELETE ON [dbo].[T_Cell_Culture] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Cell_Culture] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture] TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Cell_Culture]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Cell_Culture_T_Campaign] FOREIGN KEY([CC_Campaign_ID])
REFERENCES [T_Campaign] ([Campaign_ID])
GO
ALTER TABLE [dbo].[T_Cell_Culture] CHECK CONSTRAINT [FK_T_Cell_Culture_T_Campaign]
GO
ALTER TABLE [dbo].[T_Cell_Culture]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Cell_Culture_T_Cell_Culture_Type_Name] FOREIGN KEY([CC_Type])
REFERENCES [T_Cell_Culture_Type_Name] ([ID])
GO
ALTER TABLE [dbo].[T_Cell_Culture] CHECK CONSTRAINT [FK_T_Cell_Culture_T_Cell_Culture_Type_Name]
GO
ALTER TABLE [dbo].[T_Cell_Culture]  WITH CHECK ADD  CONSTRAINT [FK_T_Cell_Culture_T_Material_Containers] FOREIGN KEY([CC_Container_ID])
REFERENCES [T_Material_Containers] ([ID])
GO
