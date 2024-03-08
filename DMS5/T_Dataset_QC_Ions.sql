/****** Object:  Table [dbo].[T_Dataset_QC_Ions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_QC_Ions](
	[Dataset_ID] [int] NOT NULL,
	[Mz] [float] NOT NULL,
	[Max_Intensity] [real] NULL,
	[Median_Intensity] [real] NULL,
 CONSTRAINT [PK_T_Dataset_QC_Ions_Dataset_ID] PRIMARY KEY CLUSTERED 
(
	[Dataset_ID] ASC,
	[Mz] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
