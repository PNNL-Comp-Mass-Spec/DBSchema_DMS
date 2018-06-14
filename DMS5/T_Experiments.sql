/****** Object:  Table [dbo].[T_Experiments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Experiments](
	[Experiment_Num] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EX_researcher_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EX_organism_ID] [int] NOT NULL,
	[EX_reason] [varchar](500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EX_comment] [varchar](500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EX_created] [datetime] NOT NULL,
	[EX_sample_concentration] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EX_lab_notebook_ref] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EX_campaign_ID] [int] NOT NULL,
	[EX_cell_culture_list] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EX_Labelling] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Exp_ID] [int] IDENTITY(5000,1) NOT NULL,
	[EX_Container_ID] [int] NOT NULL,
	[Ex_Material_Active] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EX_enzyme_ID] [int] NOT NULL,
	[EX_sample_prep_request_ID] [int] NOT NULL,
	[EX_internal_standard_ID] [int] NOT NULL,
	[EX_postdigest_internal_std_ID] [int] NOT NULL,
	[EX_wellplate_num] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EX_well_num] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EX_Alkylation] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EX_Barcode] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EX_Tissue_ID] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EX_TissueSource_ID] [smallint] NULL,
	[EX_Disease_ID] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Last_Used] [date] NOT NULL,
 CONSTRAINT [PK_T_Experiments] PRIMARY KEY CLUSTERED 
(
	[Exp_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Experiments] TO [DDL_Viewer] AS [dbo]
GO
GRANT DELETE ON [dbo].[T_Experiments] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Experiments] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Experiments] TO [Limited_Table_Write] AS [dbo]
GO
/****** Object:  Index [IX_T_Experiments_CampaignID_ExpID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Experiments_CampaignID_ExpID] ON [dbo].[T_Experiments]
(
	[EX_campaign_ID] ASC,
	[Exp_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Experiments_Container_ID_include_Campaign_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Experiments_Container_ID_include_Campaign_ID] ON [dbo].[T_Experiments]
(
	[EX_Container_ID] ASC
)
INCLUDE ( 	[EX_campaign_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Experiments_EX_campaign_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Experiments_EX_campaign_ID] ON [dbo].[T_Experiments]
(
	[EX_campaign_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Experiments_EX_created] ******/
CREATE NONCLUSTERED INDEX [IX_T_Experiments_EX_created] ON [dbo].[T_Experiments]
(
	[EX_created] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Experiments_Exp_ID_EX_campaign_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Experiments_Exp_ID_EX_campaign_ID] ON [dbo].[T_Experiments]
(
	[Exp_ID] ASC,
	[EX_campaign_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Experiments_Experiment_Num] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Experiments_Experiment_Num] ON [dbo].[T_Experiments]
(
	[Experiment_Num] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Experiments_ExperimentNum_ContainerID_ExpID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Experiments_ExperimentNum_ContainerID_ExpID] ON [dbo].[T_Experiments]
(
	[Experiment_Num] ASC,
	[EX_Container_ID] ASC,
	[Exp_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Experiments_ExpID_CampaignID_ExpNum] ******/
CREATE NONCLUSTERED INDEX [IX_T_Experiments_ExpID_CampaignID_ExpNum] ON [dbo].[T_Experiments]
(
	[Exp_ID] ASC,
	[EX_campaign_ID] ASC,
	[Experiment_Num] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Experiments_ExpID_ContainerID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Experiments_ExpID_ContainerID] ON [dbo].[T_Experiments]
(
	[Exp_ID] ASC,
	[EX_Container_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Experiments_PrepRequestID_include_Ex_Created] ******/
CREATE NONCLUSTERED INDEX [IX_T_Experiments_PrepRequestID_include_Ex_Created] ON [dbo].[T_Experiments]
(
	[EX_sample_prep_request_ID] ASC
)
INCLUDE ( 	[EX_created]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Experiments_TissueID_include_ExperimentName_OrganismID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Experiments_TissueID_include_ExperimentName_OrganismID] ON [dbo].[T_Experiments]
(
	[EX_Tissue_ID] ASC
)
INCLUDE ( 	[Experiment_Num],
	[EX_organism_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Experiments_Wellplate_Well_Experiment] ******/
CREATE NONCLUSTERED INDEX [IX_T_Experiments_Wellplate_Well_Experiment] ON [dbo].[T_Experiments]
(
	[EX_wellplate_num] ASC,
	[EX_well_num] ASC,
	[Experiment_Num] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Experiments] ADD  CONSTRAINT [DF_T_Experiments_EX_Container_ID]  DEFAULT ((1)) FOR [EX_Container_ID]
GO
ALTER TABLE [dbo].[T_Experiments] ADD  CONSTRAINT [DF_T_Experiments_Ex_Material_Active]  DEFAULT ('Active') FOR [Ex_Material_Active]
GO
ALTER TABLE [dbo].[T_Experiments] ADD  CONSTRAINT [DF_T_Experiments_EX_enzyme_ID]  DEFAULT ((10)) FOR [EX_enzyme_ID]
GO
ALTER TABLE [dbo].[T_Experiments] ADD  CONSTRAINT [DF_T_Experiments_EX_sample_prep_request_ID]  DEFAULT ((0)) FOR [EX_sample_prep_request_ID]
GO
ALTER TABLE [dbo].[T_Experiments] ADD  CONSTRAINT [DF_T_Experiments_EX_internal_standard_ID]  DEFAULT ((0)) FOR [EX_internal_standard_ID]
GO
ALTER TABLE [dbo].[T_Experiments] ADD  CONSTRAINT [DF_T_Experiments_EX_postdigest_internal_std_ID]  DEFAULT ((0)) FOR [EX_postdigest_internal_std_ID]
GO
ALTER TABLE [dbo].[T_Experiments] ADD  CONSTRAINT [DF_T_Experiments_EX_Alkylation]  DEFAULT ('N') FOR [EX_Alkylation]
GO
ALTER TABLE [dbo].[T_Experiments] ADD  CONSTRAINT [DF_T_Experiments_Last_Used]  DEFAULT (getdate()) FOR [Last_Used]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiments_T_Campaign] FOREIGN KEY([EX_campaign_ID])
REFERENCES [dbo].[T_Campaign] ([Campaign_ID])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Campaign]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiments_T_Enzymes] FOREIGN KEY([EX_enzyme_ID])
REFERENCES [dbo].[T_Enzymes] ([Enzyme_ID])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Enzymes]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiments_T_Internal_Standards] FOREIGN KEY([EX_internal_standard_ID])
REFERENCES [dbo].[T_Internal_Standards] ([Internal_Std_Mix_ID])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Internal_Standards]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiments_T_Internal_Standards1] FOREIGN KEY([EX_postdigest_internal_std_ID])
REFERENCES [dbo].[T_Internal_Standards] ([Internal_Std_Mix_ID])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Internal_Standards1]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiments_T_Material_Containers] FOREIGN KEY([EX_Container_ID])
REFERENCES [dbo].[T_Material_Containers] ([ID])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Material_Containers]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiments_T_Organisms] FOREIGN KEY([EX_organism_ID])
REFERENCES [dbo].[T_Organisms] ([Organism_ID])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Organisms]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiments_T_Sample_Labelling] FOREIGN KEY([EX_Labelling])
REFERENCES [dbo].[T_Sample_Labelling] ([Label])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Sample_Labelling]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiments_T_Sample_Prep_Request] FOREIGN KEY([EX_sample_prep_request_ID])
REFERENCES [dbo].[T_Sample_Prep_Request] ([ID])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Sample_Prep_Request]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiments_T_Tissue_Source] FOREIGN KEY([EX_TissueSource_ID])
REFERENCES [dbo].[T_Tissue_Source] ([Tissue_Source_ID])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Tissue_Source]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiments_T_Users] FOREIGN KEY([EX_researcher_PRN])
REFERENCES [dbo].[T_Users] ([U_PRN])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Users]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH CHECK ADD  CONSTRAINT [CK_T_Experiment_Exp_name_Not_Empty] CHECK  ((isnull([Experiment_Num],'')<>''))
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [CK_T_Experiment_Exp_name_Not_Empty]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH CHECK ADD  CONSTRAINT [CK_T_Experiments_ExperimentName_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([Experiment_Num],(0))=(0)))
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [CK_T_Experiments_ExperimentName_WhiteSpace]
GO
/****** Object:  Trigger [dbo].[trig_d_Experiments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_d_Experiments] on [dbo].[T_Experiments]
For Delete
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the deleted Experiments
**
**	Auth:	mem
**	Date:	10/02/2007 mem - Initial version (Ticket #543)
**			10/31/2007 mem - Added Set NoCount statement (Ticket #569)
**    
*****************************************************/
AS
	Set NoCount On

	-- Add entries to T_Event_Log for each Experiment deleted from T_Experiments
	INSERT INTO T_Event_Log
		(
			Target_Type, 
			Target_ID, 
			Target_State, 
			Prev_Target_State, 
			Entered,
			Entered_By
		)
	SELECT	3 AS Target_Type, 
			Exp_ID AS Target_ID, 
			0 AS Target_State, 
			1 AS Prev_Target_State, 
			GETDATE(), 
			suser_sname() + '; ' + IsNull(deleted.Experiment_Num, '??')
	FROM deleted
	ORDER BY Exp_ID

GO
ALTER TABLE [dbo].[T_Experiments] ENABLE TRIGGER [trig_d_Experiments]
GO
/****** Object:  Trigger [dbo].[trig_i_Experiments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_i_Experiments] on [dbo].[T_Experiments]
For Insert
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the new Experiments
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
	SELECT 3, inserted.Exp_ID, 1, 0, GetDate()
	FROM inserted
	ORDER BY inserted.Exp_ID

GO
ALTER TABLE [dbo].[T_Experiments] ENABLE TRIGGER [trig_i_Experiments]
GO
/****** Object:  Trigger [dbo].[trig_u_Experiments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_u_Experiments] on [dbo].[T_Experiments]
For Update
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Entity_Rename_Log if the experiment is renamed
**		Renames entries in T_File_Attachment
**
**	Auth:	mem
**	Date:	07/19/2010 mem - Initial version
**			03/23/2012 mem - Now updating T_File_Attachment
**			11/28/2017 mem - Check for unchanged experiment name
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(Experiment_Num)
	Begin
		INSERT INTO T_Entity_Rename_Log (Target_Type, Target_ID, Old_Name, New_Name, Entered)
		SELECT 3, inserted.Exp_ID, deleted.Experiment_Num, inserted.Experiment_Num, GETDATE()
		FROM deleted INNER JOIN inserted ON deleted.Exp_ID = inserted.Exp_ID
          WHERE deleted.Experiment_Num <> inserted.Experiment_Num
		ORDER BY inserted.Exp_ID
		
		UPDATE T_File_Attachment
		SET Entity_ID = inserted.Experiment_Num
		FROM T_File_Attachment FA
		     INNER JOIN deleted
		       ON deleted.Experiment_Num = FA.Entity_ID
		     INNER JOIN inserted
		       ON deleted.Exp_ID = inserted.Exp_ID
		WHERE (Entity_Type = 'experiment')
	End

GO
ALTER TABLE [dbo].[T_Experiments] ENABLE TRIGGER [trig_u_Experiments]
GO
/****** Object:  Trigger [dbo].[trig_ud_T_Experiments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_ud_T_Experiments]
ON [dbo].[T_Experiments]
FOR UPDATE, DELETE AS
/****************************************************
**
**	Desc: 
**		Prevents updating or deleting all rows in the table
**
**	Auth:	mem
**	Date:	02/08/2011
**			09/11/2015 mem - Added support for the table being empty
**
*****************************************************/
BEGIN

    DECLARE @Count int
    SET @Count = @@ROWCOUNT;

	DECLARE @ExistingRows int=0
	SELECT @ExistingRows = i.rowcnt
    FROM dbo.sysobjects o INNER JOIN dbo.sysindexes i ON o.id = i.id
    WHERE o.name = 'T_Experiments' AND o.type = 'u' AND i.indid < 2

    IF @Count > 0 AND @ExistingRows > 1 AND @Count >= @ExistingRows
    BEGIN

        RAISERROR('Cannot update or delete all rows. Use a WHERE clause (see trigger trig_ud_T_Experiments)',16,1)
        ROLLBACK TRANSACTION
        RETURN;

    END

END

GO
ALTER TABLE [dbo].[T_Experiments] ENABLE TRIGGER [trig_ud_T_Experiments]
GO
