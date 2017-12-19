/****** Object:  Table [dbo].[T_Reference_Compound] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Reference_Compound](
	[Compound_ID] [int] IDENTITY(100,1) NOT NULL,
	[Compound_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Compound_Type_ID] [int] NOT NULL,
	[Organism_ID] [int] NOT NULL,
	[PubChem_CID] [int] NULL,
	[Campaign_ID] [int] NOT NULL,
	[Container_ID] [int] NOT NULL,
	[Wellplate_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Well_Number] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Contact_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Supplier] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Product_ID] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Purchase_Date] [datetime] NULL,
	[Purity] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Purchase_Quantity] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Mass] [float] NULL,
	[Modifications] [varchar](500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NOT NULL,
	[Active] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_Reference_Compound] PRIMARY KEY NONCLUSTERED 
(
	[Compound_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Reference_Compound] TO [DDL_Viewer] AS [dbo]
GO
GRANT DELETE ON [dbo].[T_Reference_Compound] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Reference_Compound] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Reference_Compound] TO [Limited_Table_Write] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Reference_Compound_ID_Name_Container] ******/
CREATE CLUSTERED INDEX [IX_T_Reference_Compound_ID_Name_Container] ON [dbo].[T_Reference_Compound]
(
	[Compound_ID] ASC,
	[Compound_Name] ASC,
	[Container_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Reference_Compound_Campaign_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Reference_Compound_Campaign_ID] ON [dbo].[T_Reference_Compound]
(
	[Campaign_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Reference_Compound_Container_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Reference_Compound_Container_ID] ON [dbo].[T_Reference_Compound]
(
	[Container_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Reference_Compound_Created] ******/
CREATE NONCLUSTERED INDEX [IX_T_Reference_Compound_Created] ON [dbo].[T_Reference_Compound]
(
	[Created] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Reference_Compound_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Reference_Compound_Name] ON [dbo].[T_Reference_Compound]
(
	[Compound_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Reference_Compound_Name_ContainerID_CompoundID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Reference_Compound_Name_ContainerID_CompoundID] ON [dbo].[T_Reference_Compound]
(
	[Compound_Name] ASC,
	[Container_ID] ASC,
	[Compound_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Reference_Compound] ADD  CONSTRAINT [DF_T_Reference_Compound_Container_ID]  DEFAULT ((1)) FOR [Container_ID]
GO
ALTER TABLE [dbo].[T_Reference_Compound] ADD  CONSTRAINT [DF_T_Reference_Compound_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_Reference_Compound] ADD  CONSTRAINT [DF_T_Reference_Compound_Active]  DEFAULT ((1)) FOR [Active]
GO
ALTER TABLE [dbo].[T_Reference_Compound]  WITH CHECK ADD  CONSTRAINT [FK_T_Reference_Compound_T_Campaign] FOREIGN KEY([Campaign_ID])
REFERENCES [dbo].[T_Campaign] ([Campaign_ID])
GO
ALTER TABLE [dbo].[T_Reference_Compound] CHECK CONSTRAINT [FK_T_Reference_Compound_T_Campaign]
GO
ALTER TABLE [dbo].[T_Reference_Compound]  WITH CHECK ADD  CONSTRAINT [FK_T_Reference_Compound_T_Material_Containers] FOREIGN KEY([Container_ID])
REFERENCES [dbo].[T_Material_Containers] ([ID])
GO
ALTER TABLE [dbo].[T_Reference_Compound] CHECK CONSTRAINT [FK_T_Reference_Compound_T_Material_Containers]
GO
ALTER TABLE [dbo].[T_Reference_Compound]  WITH CHECK ADD  CONSTRAINT [FK_T_Reference_Compound_T_Organisms] FOREIGN KEY([Organism_ID])
REFERENCES [dbo].[T_Organisms] ([Organism_ID])
GO
ALTER TABLE [dbo].[T_Reference_Compound] CHECK CONSTRAINT [FK_T_Reference_Compound_T_Organisms]
GO
ALTER TABLE [dbo].[T_Reference_Compound]  WITH CHECK ADD  CONSTRAINT [FK_T_Reference_Compound_T_Reference_Compound_Type_Name] FOREIGN KEY([Compound_Type_ID])
REFERENCES [dbo].[T_Reference_Compound_Type_Name] ([Compound_Type_ID])
GO
ALTER TABLE [dbo].[T_Reference_Compound] CHECK CONSTRAINT [FK_T_Reference_Compound_T_Reference_Compound_Type_Name]
GO
ALTER TABLE [dbo].[T_Reference_Compound]  WITH CHECK ADD  CONSTRAINT [FK_T_Reference_Compound_T_Users] FOREIGN KEY([Contact_PRN])
REFERENCES [dbo].[T_Users] ([U_PRN])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Reference_Compound] CHECK CONSTRAINT [FK_T_Reference_Compound_T_Users]
GO
ALTER TABLE [dbo].[T_Reference_Compound]  WITH CHECK ADD  CONSTRAINT [CK_T_Reference_Compound_Name_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([Compound_Name],(1))=(0)))
GO
ALTER TABLE [dbo].[T_Reference_Compound] CHECK CONSTRAINT [CK_T_Reference_Compound_Name_WhiteSpace]
GO
/****** Object:  Trigger [dbo].[trig_d_Reference_Compound] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_d_Reference_Compound] on [dbo].[T_Reference_Compound]
For Delete
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the deleted compound
**
**	Auth:	mem
**	Date:	11/27/2017 mem - Initial version
**    
*****************************************************/
AS
	Set NoCount On

	-- Add entries to T_Event_Log for each Compound deleted from T_Reference_Compound
	INSERT INTO T_Event_Log
		(
			Target_Type, 
			Target_ID, 
			Target_State, 
			Prev_Target_State, 
			Entered,
			Entered_By
		)
	SELECT	13 AS Target_Type, 
			Compound_ID AS Target_ID, 
			0 AS Target_State, 
			1 AS Prev_Target_State, 
			GETDATE(), 
			suser_sname() + '; ' + IsNull(deleted.Compound_Name, '??')
	FROM deleted
	ORDER BY Compound_ID

GO
/****** Object:  Trigger [dbo].[trig_i_Reference_Compound] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_i_Reference_Compound] on [dbo].[T_Reference_Compound]
For Insert
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the new compound
**
**	Auth:	mem
**	Date:	11/27/2017 mem - Initial version
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
	SELECT 13, inserted.Compound_ID, 1, 0, GetDate()
	FROM inserted
	ORDER BY inserted.Compound_ID

GO
/****** Object:  Trigger [dbo].[trig_u_Reference_Compound] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_u_Reference_Compound] on [dbo].[T_Reference_Compound]
For Update
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Entity_Rename_Log if the compound is renamed
**
**	Auth:	mem
**	Date:	11/28/2017 mem - Initial version
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(Compound_Name)
	Begin
		INSERT INTO T_Entity_Rename_Log (Target_Type, Target_ID, Old_Name, New_Name, Entered)
		SELECT 13, inserted.Compound_ID, deleted.Compound_Name, inserted.Compound_Name, GETDATE()
		FROM deleted INNER JOIN inserted ON deleted.Compound_ID = inserted.Compound_ID
          WHERE deleted.Compound_Name <> inserted.Compound_Name
		ORDER BY inserted.Compound_ID
	End

GO
