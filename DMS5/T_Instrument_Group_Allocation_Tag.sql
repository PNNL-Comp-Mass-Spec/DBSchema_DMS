/****** Object:  Table [dbo].[T_Instrument_Group_Allocation_Tag] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Instrument_Group_Allocation_Tag](
	[Allocation_Tag] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Allocation_Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Instrument_Group_Allocation_Tag] PRIMARY KEY CLUSTERED 
(
	[Allocation_Tag] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
