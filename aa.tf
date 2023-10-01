provider "aws" {
  region = "eu-central-1"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "CodePipelineServiceRole-tf-static-site-GitHub-to-S3"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
    }]
  })
}

resource "aws_codepipeline" "example" {
  name     = "tf-static-site-GitHub-to-S3"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = "codepipeline-eu-central-1-320847271875"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      input_artifacts  = []
      output_artifacts = [{
        name = "SourceArtifact"
      }]
      configuration = {
        BranchName       = "main"
        ConnectionArn    = "arn:aws:codestar-connections:eu-central-1:671231939531:connection/5b3a1626-85fa-4d40-8878-156a4264fe3a"
        FullRepositoryId = "OmerMeister/tf-static-site-webcontent"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name     = "Deploy"
      category = "Deploy"
      owner    = "AWS"
      provider = "S3"
      version  = "1"
      input_artifacts  = [{
        name = "SourceArtifact"
      }]
      output_artifacts = []
      configuration = {
        BucketName = "meister.lol"
        Extract    = "true"
      }
    }
  }

  stage {
    name = "InvalidateCloudFront"

    action {
      name     = "InvalidateCloudFrontLambda"
      category = "Invoke"
      owner    = "AWS"
      provider = "Lambda"
      version  = "1"
      input_artifacts  = []
      output_artifacts = []
      configuration = {
        FunctionName = "test123"
      }
    }
  }
}

data "aws_codepipeline" "example_metadata" {
  name = aws_codepipeline.example.name
}

output "pipeline_arn" {
  value = data.aws_codepipeline.example_metadata.arn
}