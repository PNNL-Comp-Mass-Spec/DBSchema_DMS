/****** Object:  Table [dbo].[T_Cell_Culture] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cell_Culture](
	[CC_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CC_Source_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CC_Contact_PRN] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CC_PI_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CC_Type] [int] NULL,
	[CC_Reason] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CC_Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CC_Campaign_ID] [int] NULL,
	[CC_ID] [int] IDENTITY(200,1) NOT NULL,
	[CC_Container_ID] [int] NOT NULL,
	[CC_Material_Active] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CC_Created] [datetime] NULL,
	[Gene_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Gene_Location] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Mod_Count] [smallint] NULL,
	[Modifications] [varchar](500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Mass] [float] NULL,
	[Purchase_Date] [datetime] NULL,
	[Peptide_Purity] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Purchase_Quantity] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Cached_Organism_List] [varchar](1500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Cell_Culture] PRIMARY KEY NONCLUSTERED 
(
	[CC_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Cell_Culture] TO [DDL_Viewer] AS [dbo]
GO
GRANT DELETE ON [dbo].[T_Cell_Culture] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Cell_Culture] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture] TO [Limited_Table_Write] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Cell_Culture_ID_Name_Container] ******/
CREATE CLUSTERED INDEX [IX_T_Cell_Culture_ID_Name_Container] ON [dbo].[T_Cell_Culture]
(
	[CC_ID] ASC,
	[CC_Name] ASC,
	[CC_Container_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Cell_Culture_CC_Campaign_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Cell_Culture_CC_Campaign_ID] ON [dbo].[T_Cell_Culture]
(
	[CC_Campaign_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Cell_Culture_CC_Created] ******/
CREATE NONCLUSTERED INDEX [IX_T_Cell_Culture_CC_Created] ON [dbo].[T_Cell_Culture]
(
	[CC_Created] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Cell_Culture_CC_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Cell_Culture_CC_Name] ON [dbo].[T_Cell_Culture]
(
	[CC_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Cell_Culture_CCName_ContainerID_CCID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Cell_Culture_CCName_ContainerID_CCID] ON [dbo].[T_Cell_Culture]
(
	[CC_Name] ASC,
	[CC_Container_ID] ASC,
	[CC_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Cell_Culture_Container_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Cell_Culture_Container_ID] ON [dbo].[T_Cell_Culture]
(
	[CC_Container_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Cell_Culture] ADD  CONSTRAINT [DF_T_Cell_Culture_CC_Container_ID]  DEFAULT ((1)) FOR [CC_Container_ID]
GO
ALTER TABLE [dbo].[T_Cell_Culture] ADD  CONSTRAINT [DF_T_Cell_Culture_CC_Material_Active]  DEFAULT ('Active') FOR [CC_Material_Active]
GO
ALTER TABLE [dbo].[T_Cell_Culture]  WITH CHECK ADD  CONSTRAINT [FK_T_Cell_Culture_T_Campaign] FOREIGN KEY([CC_Campaign_ID])
REFERENCES [dbo].[T_Campaign] ([Campaign_ID])
GO
ALTER TABLE [dbo].[T_Cell_Culture] CHECK CONSTRAINT [FK_T_Cell_Culture_T_Campaign]
GO
ALTER TABLE [dbo].[T_Cell_Culture]  WITH CHECK ADD  CONSTRAINT [FK_T_Cell_Culture_T_Cell_Culture_Type_Name] FOREIGN KEY([CC_Type])
REFERENCES [dbo].[T_Cell_Culture_Type_Name] ([ID])
GO
ALTER TABLE [dbo].[T_Cell_Culture] CHECK CONSTRAINT [FK_T_Cell_Culture_T_Cell_Culture_Type_Name]
GO
ALTER TABLE [dbo].[T_Cell_Culture]  WITH CHECK ADD  CONSTRAINT [FK_T_Cell_Culture_T_Material_Containers] FOREIGN KEY([CC_Container_ID])
REFERENCES [dbo].[T_Material_Containers] ([ID])
GO
ALTER TABLE [dbo].[T_Cell_Culture] CHECK CONSTRAINT [FK_T_Cell_Culture_T_Material_Containers]
GO
ALTER TABLE [dbo].[T_Cell_Culture]  WITH CHECK ADD  CONSTRAINT [FK_T_Cell_Culture_T_Users] FOREIGN KEY([CC_PI_PRN])
REFERENCES [dbo].[T_Users] ([U_PRN])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Cell_Culture] CHECK CONSTRAINT [FK_T_Cell_Culture_T_Users]
GO
ALTER TABLE [dbo].[T_Cell_Culture]  WITH CHECK ADD  CONSTRAINT [CK_T_Cell_Culture_CellCultureName_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([CC_Name],(1))=(0)))
GO
ALTER TABLE [dbo].[T_Cell_Culture] CHECK CONSTRAINT [CK_T_Cell_Culture_CellCultureName_WhiteSpace]
GO
/****** Object:  Trigger [dbo].[trig_d_Cell_Culture] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_d_Cell_Culture] on [dbo].[T_Cell_Culture]
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
/****** Object:  Trigger [dbo].[trig_i_Cell_Culture] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_i_Cell_Culture] on [dbo].[T_Cell_Culture]
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
/****** Object:  Trigger [dbo].[trig_u_Cell_Culture] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_u_Cell_Culture] on [dbo].[T_Cell_Culture]
For Update
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Entity_Rename_Log if the cell culture is renamed
**
**	Auth:	mem
**	Date:	07/19/2010 mem - Initial version
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(CC_Name)
	Begin
		INSERT INTO T_Entity_Rename_Log (Target_Type, Target_ID, Old_Name, New_Name, Entered)
		SELECT 2, inserted.CC_ID, deleted.CC_Name, inserted.CC_Name, GETDATE()
		FROM deleted INNER JOIN inserted ON deleted.CC_ID = inserted.CC_ID
		ORDER BY inserted.CC_ID
	End


GO
