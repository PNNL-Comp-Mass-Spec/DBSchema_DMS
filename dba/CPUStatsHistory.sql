/****** Object:  Table [dbo].[CPUStatsHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUStatsHistory](
	[CPUStatsHistoryID] [int] IDENTITY(1,1) NOT NULL,
	[SQLProcessPercent] [int] NULL,
	[SystemIdleProcessPercent] [int] NULL,
	[OtherProcessPerecnt] [int] NULL,
	[DateStamp] [datetime] NOT NULL,
 CONSTRAINT [PK_CPUStatsHistory] PRIMARY KEY CLUSTERED 
(
	[CPUStatsHistoryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[CPUStatsHistory] ADD  CONSTRAINT [DF_CPUStatsHistory_DateStamp]  DEFAULT (getdate()) FOR [DateStamp]
GO
