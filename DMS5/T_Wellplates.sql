/****** Object:  Table [dbo].[T_Wellplates] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Wellplates](
	[ID] [int] IDENTITY(1000,1) NOT NULL,
	[WP_Well_Plate_Num] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[WP_Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Wellplates] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY],
 CONSTRAINT [IX_T_Wellplates] UNIQUE NONCLUSTERED 
(
	[WP_Well_Plate_Num] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Wellplates]  WITH CHECK ADD  CONSTRAINT [CK_T_Wellplates_WellPlateName_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([WP_Well_Plate_Num],(1))=(0)))
GO
ALTER TABLE [dbo].[T_Wellplates] CHECK CONSTRAINT [CK_T_Wellplates_WellPlateName_WhiteSpace]
GO
ALTER TABLE [dbo].[T_Wellplates] ADD  CONSTRAINT [DF_T_Wellplates_Created]  DEFAULT (getdate()) FOR [Created]
GO
