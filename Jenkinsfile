pipeline {
  agent any
  stages {
    stage('build') {
      parallel {
        stage('build') {
          steps {
            echo 'build'
          }
        }

        stage('test') {
          steps {
            echo 'test'
          }
        }

      }
    }

    stage('successful') {
      steps {
        echo 'success'
      }
    }

  }
}