/****** Object:  Table [dbo].[T_EMSL_DMS_Instrument_Mapping] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EMSL_DMS_Instrument_Mapping](
	[EUS_Instrument_ID] [int] NOT NULL,
	[DMS_Instrument_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_EMSL_DMS_Instrument_Mapping] PRIMARY KEY CLUSTERED 
(
	[EUS_Instrument_ID] ASC,
	[DMS_Instrument_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_T_EMSL_DMS_Instrument_Mapping_DMS_InstID] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_EMSL_DMS_Instrument_Mapping_DMS_InstID] ON [dbo].[T_EMSL_DMS_Instrument_Mapping]
(
	[DMS_Instrument_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_EMSL_DMS_Instrument_Mapping]  WITH CHECK ADD  CONSTRAINT [FK_T_EMSL_DMS_Instrument_Mapping_T_EMSL_Instruments] FOREIGN KEY([EUS_Instrument_ID])
REFERENCES [dbo].[T_EMSL_Instruments] ([EUS_Instrument_ID])
GO
ALTER TABLE [dbo].[T_EMSL_DMS_Instrument_Mapping] CHECK CONSTRAINT [FK_T_EMSL_DMS_Instrument_Mapping_T_EMSL_Instruments]
GO
ALTER TABLE [dbo].[T_EMSL_DMS_Instrument_Mapping]  WITH CHECK ADD  CONSTRAINT [FK_T_EMSL_DMS_Instrument_Mapping_T_Instrument_Name] FOREIGN KEY([DMS_Instrument_ID])
REFERENCES [dbo].[T_Instrument_Name] ([Instrument_ID])
GO
ALTER TABLE [dbo].[T_EMSL_DMS_Instrument_Mapping] CHECK CONSTRAINT [FK_T_EMSL_DMS_Instrument_Mapping_T_Instrument_Name]
GO
