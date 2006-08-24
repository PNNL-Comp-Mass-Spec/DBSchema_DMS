/****** Object:  Table [dbo].[T_Wellplates] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Wellplates](
	[WP_ID] [int] IDENTITY(1,1) NOT NULL,
	[WP_Well_Plate_Num] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[WP_Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Wellplates] PRIMARY KEY CLUSTERED 
(
	[WP_Well_Plate_Num] ASC
) ON [PRIMARY],
 CONSTRAINT [IX_T_Wellplates] UNIQUE NONCLUSTERED 
(
	[WP_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
