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
	[EX_Labelling] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Exp_ID] [int] IDENTITY(5000,1) NOT NULL,
	[EX_enzyme_ID] [int] NOT NULL CONSTRAINT [DF_T_Experiments_EX_enzyme_ID]  DEFAULT (10),
	[EX_sample_prep_request_ID] [int] NOT NULL CONSTRAINT [DF_T_Experiments_EX_sample_prep_request_ID]  DEFAULT (0),
	[EX_internal_standard_ID] [int] NOT NULL CONSTRAINT [DF_T_Experiments_EX_internal_standard_ID]  DEFAULT (0),
	[EX_postdigest_internal_std_ID] [int] NOT NULL CONSTRAINT [DF_T_Experiments_EX_postdigest_internal_std_ID]  DEFAULT (0),
 CONSTRAINT [PK_T_Experiments] PRIMARY KEY NONCLUSTERED 
(
	[Exp_ID] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Experiments_Experiment_Num] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Experiments_Experiment_Num] ON [dbo].[T_Experiments] 
(
	[Experiment_Num] ASC
) ON [PRIMARY]
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
**    
*****************************************************/
AS
	-- Add entries to T_Event_Log for each Experiments deleted from T_Experiments
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
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
	SELECT 3, inserted.Exp_ID, 1, 0, GetDate()
	FROM inserted
	ORDER BY inserted.Exp_ID

GO
GRANT SELECT ON [dbo].[T_Experiments] TO [Limited_Table_Write]
GO
GRANT DELETE ON [dbo].[T_Experiments] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Experiments] ([Experiment_Num]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] ([Experiment_Num]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Experiments] ([EX_researcher_PRN]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] ([EX_researcher_PRN]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Experiments] ([EX_organism_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] ([EX_organism_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Experiments] ([EX_reason]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] ([EX_reason]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Experiments] ([EX_comment]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] ([EX_comment]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Experiments] ([EX_created]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] ([EX_created]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Experiments] ([EX_sample_concentration]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] ([EX_sample_concentration]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Experiments] ([EX_lab_notebook_ref]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] ([EX_lab_notebook_ref]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Experiments] ([EX_campaign_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] ([EX_campaign_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Experiments] ([EX_cell_culture_list]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] ([EX_cell_culture_list]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Experiments] ([EX_Labelling]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] ([EX_Labelling]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Experiments] ([Exp_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] ([Exp_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Experiments] ([EX_enzyme_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] ([EX_enzyme_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Experiments] ([EX_sample_prep_request_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] ([EX_sample_prep_request_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Experiments] ([EX_internal_standard_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] ([EX_internal_standard_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Experiments] ([EX_postdigest_internal_std_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Experiments] ([EX_postdigest_internal_std_ID]) TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Experiments_T_Campaign] FOREIGN KEY([EX_campaign_ID])
REFERENCES [T_Campaign] ([Campaign_ID])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Campaign]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Experiments_T_Enzymes] FOREIGN KEY([EX_enzyme_ID])
REFERENCES [T_Enzymes] ([Enzyme_ID])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Enzymes]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Experiments_T_Internal_Standards] FOREIGN KEY([EX_internal_standard_ID])
REFERENCES [T_Internal_Standards] ([Internal_Std_Mix_ID])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Internal_Standards]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Experiments_T_Internal_Standards1] FOREIGN KEY([EX_postdigest_internal_std_ID])
REFERENCES [T_Internal_Standards] ([Internal_Std_Mix_ID])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Internal_Standards1]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Experiments_T_Organisms] FOREIGN KEY([EX_organism_ID])
REFERENCES [T_Organisms] ([Organism_ID])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Organisms]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Experiments_T_Sample_Labelling] FOREIGN KEY([EX_Labelling])
REFERENCES [T_Sample_Labelling] ([Label])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Sample_Labelling]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Experiments_T_Sample_Prep_Request] FOREIGN KEY([EX_sample_prep_request_ID])
REFERENCES [T_Sample_Prep_Request] ([ID])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Sample_Prep_Request]
GO
ALTER TABLE [dbo].[T_Experiments]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Experiments_T_Users] FOREIGN KEY([EX_researcher_PRN])
REFERENCES [T_Users] ([U_PRN])
GO
ALTER TABLE [dbo].[T_Experiments] CHECK CONSTRAINT [FK_T_Experiments_T_Users]
GO
