/****** Object:  Table [dbo].[T_Cached_Dataset_Instruments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cached_Dataset_Instruments](
	[Dataset_ID] [int] NOT NULL,
	[Instrument_ID] [int] NOT NULL,
	[Instrument] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Cached_Dataset_Instruments] PRIMARY KEY CLUSTERED 
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_T_Cached_Dataset_Instruments_InstrumentID_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Cached_Dataset_Instruments_InstrumentID_DatasetID] ON [dbo].[T_Cached_Dataset_Instruments]
(
	[Instrument_ID] ASC,
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Cached_Dataset_Instruments_InstrumentName_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Cached_Dataset_Instruments_InstrumentName_DatasetID] ON [dbo].[T_Cached_Dataset_Instruments]
(
	[Instrument] ASC,
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Instruments]  WITH CHECK ADD  CONSTRAINT [FK_T_Cached_Dataset_Instruments_T_Dataset] FOREIGN KEY([Dataset_ID])
REFERENCES [dbo].[T_Dataset] ([Dataset_ID])
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Instruments] CHECK CONSTRAINT [FK_T_Cached_Dataset_Instruments_T_Dataset]
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Instruments]  WITH CHECK ADD  CONSTRAINT [FK_T_Cached_Dataset_Instruments_T_Instrument_Name] FOREIGN KEY([Instrument_ID])
REFERENCES [dbo].[T_Instrument_Name] ([Instrument_ID])
GO
ALTER TABLE [dbo].[T_Cached_Dataset_Instruments] CHECK CONSTRAINT [FK_T_Cached_Dataset_Instruments_T_Instrument_Name]
GO
