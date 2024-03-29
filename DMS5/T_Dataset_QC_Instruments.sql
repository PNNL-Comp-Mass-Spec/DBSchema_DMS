/****** Object:  Table [dbo].[T_Dataset_QC_Instruments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_QC_Instruments](
	[IN_name] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Instrument_ID] [int] NOT NULL,
	[Last_Updated] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Dataset_QC_Instruments] PRIMARY KEY CLUSTERED 
(
	[IN_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Dataset_QC_Instruments] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Dataset_QC_Instruments] ADD  CONSTRAINT [DF_T_Dataset_QC_Instruments_Last_Updated]  DEFAULT (getdate()) FOR [Last_Updated]
GO
