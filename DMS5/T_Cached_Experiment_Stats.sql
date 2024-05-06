/****** Object:  Table [dbo].[T_Cached_Experiment_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cached_Experiment_Stats](
	[Exp_ID] [int] NOT NULL,
	[Dataset_Count] [int] NOT NULL,
	[Factor_Count] [int] NOT NULL,
	[Most_Recent_Dataset] [datetime] NULL,
	[Update_Required] [tinyint] NOT NULL,
	[Last_Affected] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_T_Cached_Experiment_Stats] PRIMARY KEY CLUSTERED 
(
	[Exp_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_T_Cached_Experiment_Stats_Update_Required] ******/
CREATE NONCLUSTERED INDEX [IX_T_Cached_Experiment_Stats_Update_Required] ON [dbo].[T_Cached_Experiment_Stats]
(
	[Update_Required] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Cached_Experiment_Stats] ADD  CONSTRAINT [DF_T_Cached_Experiment_Stats_Dataset_Count]  DEFAULT ((0)) FOR [Dataset_Count]
GO
ALTER TABLE [dbo].[T_Cached_Experiment_Stats] ADD  CONSTRAINT [DF_T_Cached_Experiment_Stats_Factor_Count]  DEFAULT ((0)) FOR [Factor_Count]
GO
ALTER TABLE [dbo].[T_Cached_Experiment_Stats] ADD  CONSTRAINT [DF_T_Cached_Experiment_Stats_Update_Required]  DEFAULT ((0)) FOR [Update_Required]
GO
ALTER TABLE [dbo].[T_Cached_Experiment_Stats] ADD  CONSTRAINT [DF_T_Cached_Experiment_Stats_Last_affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_Cached_Experiment_Stats]  WITH CHECK ADD  CONSTRAINT [FK_T_Cached_Experiment_Stats_T_Experiments] FOREIGN KEY([Exp_ID])
REFERENCES [dbo].[T_Experiments] ([Exp_ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Cached_Experiment_Stats] CHECK CONSTRAINT [FK_T_Cached_Experiment_Stats_T_Experiments]
GO
/****** Object:  Trigger [dbo].[trig_u_T_Cached_Experiment_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_u_T_Cached_Experiment_Stats] on [dbo].[T_Cached_Experiment_Stats]
FOR UPDATE
/****************************************************
**
**  Desc:
**      Updates Last_Affected in T_Cached_Experiment_Stats
**
**  Auth:   mem
**  Date:   05/05/2024 - Initial version
**
*****************************************************/
AS
    If @@RowCount = 0
        Return

    Set NoCount On

    If Update(Dataset_Count) OR
       Update(Factor_Count) OR
       Update(Most_Recent_Dataset)
    Begin
        UPDATE T_Cached_Experiment_Stats
        SET Last_Affected = GetDate()
        WHERE Exp_ID IN (SELECT Exp_ID FROM inserted)
    End

GO
ALTER TABLE [dbo].[T_Cached_Experiment_Stats] ENABLE TRIGGER [trig_u_T_Cached_Experiment_Stats]
GO
