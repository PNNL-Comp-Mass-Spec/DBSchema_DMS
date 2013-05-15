/****** Object:  Table [dbo].[T_Instrument_Class] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Instrument_Class](
	[IN_class] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[is_purgable] [tinyint] NOT NULL,
	[raw_data_type] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[requires_preparation] [tinyint] NOT NULL,
	[x_Allowed_Dataset_Types] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Params] [xml] NULL,
	[Comment] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Instrument_Class] PRIMARY KEY CLUSTERED 
(
	[IN_class] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Instrument_Class]  WITH CHECK ADD  CONSTRAINT [FK_T_Instrument_Class_T_Instrument_Data_Type_Name] FOREIGN KEY([raw_data_type])
REFERENCES [T_Instrument_Data_Type_Name] ([Raw_Data_Type_Name])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Instrument_Class] CHECK CONSTRAINT [FK_T_Instrument_Class_T_Instrument_Data_Type_Name]
GO
ALTER TABLE [dbo].[T_Instrument_Class] ADD  CONSTRAINT [DF_T_Instrument_Class_is_purgable]  DEFAULT (0) FOR [is_purgable]
GO
ALTER TABLE [dbo].[T_Instrument_Class] ADD  CONSTRAINT [DF_T_Instrument_Class_raw_data_type]  DEFAULT ('na') FOR [raw_data_type]
GO
ALTER TABLE [dbo].[T_Instrument_Class] ADD  CONSTRAINT [DF_T_Instrument_Class_requires_preparation]  DEFAULT (0) FOR [requires_preparation]
GO
