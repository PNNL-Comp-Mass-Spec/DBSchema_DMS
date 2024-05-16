/****** Object:  Table [dbo].[T_Cached_Dataset_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cached_Dataset_Stats](
	[Dataset_ID] [int] NOT NULL,
	[Instrument_ID] [int] NOT NULL,
	[Instrument] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Job_Count] [int] NOT NULL,
	[PSM_Job_Count] [int] NOT NULL,
	[Max_Total_PSMs] [int] NOT NULL,
	[Max_Unique_Peptides] [int] NOT NULL,
	[Max_Unique_Proteins] [int] NOT NULL,
	[Max_Total_PSMs_FDR_Filter] [int] NOT NULL,
	[Max_Unique_Peptides_FDR_Filter] [int] NOT NULL,
	[Max_Unique_Proteins_FDR_Filter] [int] NOT NULL,
	[Update_Required] [tinyint] NOT NULL,
	[Last_Affected] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_T_Cached_Dataset_Stats] PRIMARY KEY CLUSTERED 
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_T_Cached_Dataset_Stats_InstrumentID_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Cached_Dataset_Stats_InstrumentID_DatasetID] ON [dbo].[T_Cached_Dataset_Stats]
(
	[Instrument_ID] ASC,
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Cached_Dataset_Stats_InstrumentName_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Cached_Dataset_Stats_InstrumentName_DatasetID] ON [dbo].[T_Cached_Dataset_Stats]
(
	[Instrument] ASC,
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Cached_Dataset_Stats_Update_Required] ******/
CREATE NONCLUSTERED INDEX [IX_T_Cached_Dataset_Stats_Update_Required] ON [dbo].[T_Cached_Dataset_Stats]
(
	[Update_Required] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Stats] ADD  CONSTRAINT [DF_T_Cached_Dataset_Stats_Job_Count]  DEFAULT ((0)) FOR [Job_Count]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Stats] ADD  CONSTRAINT [DF_T_Cached_Dataset_Stats_PSM_Job_Count]  DEFAULT ((0)) FOR [PSM_Job_Count]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Stats] ADD  CONSTRAINT [DF_T_Cached_Dataset_Stats_Max_Total_PSMs]  DEFAULT ((0)) FOR [Max_Total_PSMs]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Stats] ADD  CONSTRAINT [DF_T_Cached_Dataset_Stats_Max_Unique_Peptides]  DEFAULT ((0)) FOR [Max_Unique_Peptides]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Stats] ADD  CONSTRAINT [DF_T_Cached_Dataset_Stats_Max_Unique_Proteins]  DEFAULT ((0)) FOR [Max_Unique_Proteins]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Stats] ADD  CONSTRAINT [DF_T_Cached_Dataset_Stats_Max_Total_PSMs_FDR_Filter]  DEFAULT ((0)) FOR [Max_Total_PSMs_FDR_Filter]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Stats] ADD  CONSTRAINT [DF_T_Cached_Dataset_Stats_Max_Unique_Peptides_FDR_Filter]  DEFAULT ((0)) FOR [Max_Unique_Peptides_FDR_Filter]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Stats] ADD  CONSTRAINT [DF_T_Cached_Dataset_Stats_Max_Unique_Proteins_FDR_Filter]  DEFAULT ((0)) FOR [Max_Unique_Proteins_FDR_Filter]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Stats] ADD  CONSTRAINT [DF_T_Cached_Dataset_Stats_Update_Required]  DEFAULT ((1)) FOR [Update_Required]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Stats] ADD  CONSTRAINT [DF_T_Cached_Dataset_Stats_Last_affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Stats]  WITH CHECK ADD  CONSTRAINT [FK_T_Cached_Dataset_Stats_T_Dataset] FOREIGN KEY([Dataset_ID])
REFERENCES [dbo].[T_Dataset] ([Dataset_ID])
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Stats] CHECK CONSTRAINT [FK_T_Cached_Dataset_Stats_T_Dataset]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Stats]  WITH CHECK ADD  CONSTRAINT [FK_T_Cached_Dataset_Stats_T_Instrument_Name] FOREIGN KEY([Instrument_ID])
REFERENCES [dbo].[T_Instrument_Name] ([Instrument_ID])
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Stats] CHECK CONSTRAINT [FK_T_Cached_Dataset_Stats_T_Instrument_Name]
GO
/****** Object:  Trigger [dbo].[trig_u_T_Cached_Dataset_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_u_T_Cached_Dataset_Stats] on [dbo].[T_Cached_Dataset_Stats]
FOR UPDATE
/****************************************************
**
**  Desc:
**      Updates Last_Affected in T_Cached_Dataset_Stats
**
**  Auth:   mem
**  Date:   05/08/2024 - Initial version
**          05/15/2024 - Examine newly added columns: Max_Total_PSMs, Max_Unique_Peptides, Max_Unique_Proteins, and Max_Unique_Peptides_FDR_Filter
**
*****************************************************/
AS
    If @@RowCount = 0
        Return

    Set NoCount On

    If Update(Job_Count) OR
       Update(PSM_Job_Count) OR
	   Update(Max_Total_PSMs) OR
	   Update(Max_Unique_Peptides) OR
	   Update(Max_Unique_Proteins) OR
	   Update(Max_Unique_Peptides_FDR_Filter) OR
       Update(Instrument_ID) OR
       Update(Instrument)
    Begin
        UPDATE T_Cached_Dataset_Stats
        SET Last_Affected = GetDate()
        WHERE Dataset_ID IN (SELECT Dataset_ID FROM inserted)
    End

GO
ALTER TABLE [dbo].[T_Cached_Dataset_Stats] ENABLE TRIGGER [trig_u_T_Cached_Dataset_Stats]
GO
