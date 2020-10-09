/****** Object:  Table [dbo].[T_Separation_Group] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Separation_Group](
	[Sep_Group] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Active] [tinyint] NOT NULL,
	[Sample_Prep_Visible] [tinyint] NOT NULL,
	[Fraction_Count] [smallint] NOT NULL,
 CONSTRAINT [PK_T_Separation_Group] PRIMARY KEY CLUSTERED 
(
	[Sep_Group] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Separation_Group] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Separation_Group] ADD  CONSTRAINT [DF_T_Separation_Group_Comment]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_Separation_Group] ADD  CONSTRAINT [DF_T_Separation_Group_Active]  DEFAULT ((1)) FOR [Active]
GO
ALTER TABLE [dbo].[T_Separation_Group] ADD  CONSTRAINT [DF_T_Separation_Group_Sample_Prep_Visible]  DEFAULT ((1)) FOR [Sample_Prep_Visible]
GO
ALTER TABLE [dbo].[T_Separation_Group] ADD  CONSTRAINT [DF_T_Separation_Group_Fraction_Count]  DEFAULT ((0)) FOR [Fraction_Count]
GO
