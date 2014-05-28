/****** Object:  Table [dbo].[T_Dataset_Info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_Info](
	[Dataset_ID] [int] NOT NULL,
	[ScanCountMS] [int] NOT NULL,
	[ScanCountMSn] [int] NOT NULL,
	[TIC_Max_MS] [real] NULL,
	[TIC_Max_MSn] [real] NULL,
	[BPI_Max_MS] [real] NULL,
	[BPI_Max_MSn] [real] NULL,
	[TIC_Median_MS] [real] NULL,
	[TIC_Median_MSn] [real] NULL,
	[BPI_Median_MS] [real] NULL,
	[BPI_Median_MSn] [real] NULL,
	[Elution_Time_Max] [real] NULL,
	[Scan_Types] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Last_Affected] [datetime] NOT NULL,
	[ProfileScanCount_MS] [int] NULL,
	[ProfileScanCount_MSn] [int] NULL,
	[CentroidScanCount_MS] [int] NULL,
	[CentroidScanCount_MSn] [int] NULL,
 CONSTRAINT [PK_T_Dataset_ScanInfo] PRIMARY KEY CLUSTERED 
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Dataset_Info]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_Info_T_Dataset] FOREIGN KEY([Dataset_ID])
REFERENCES [dbo].[T_Dataset] ([Dataset_ID])
GO
ALTER TABLE [dbo].[T_Dataset_Info] CHECK CONSTRAINT [FK_T_Dataset_Info_T_Dataset]
GO
