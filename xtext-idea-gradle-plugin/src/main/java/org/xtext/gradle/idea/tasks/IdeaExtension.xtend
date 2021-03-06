package org.xtext.gradle.idea.tasks

import groovy.lang.Closure
import java.io.File
import java.util.List
import java.util.concurrent.Callable
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.Project
import org.gradle.api.file.FileCollection

import static extension org.xtext.gradle.idea.tasks.GradleExtensions.*

@Accessors
class IdeaExtension {
	val Project project
	val IdeaPluginRepositories pluginRepositories
	val IdeaPluginDependencies pluginDependencies
	Object ideaHome
	String ideaVersion
	DownloadIdea downloadIdea
	DownloadIdeaPlugins downloadPlugins

	new (Project project) {
		this.project = project
		pluginRepositories = new IdeaPluginRepositories
		pluginDependencies = new IdeaPluginDependencies
	}

	def List<Object> getIdeaLibs() {
		val result = <Object>newArrayList
		result += pluginDependencies.projectDependencies.map [
			project.project(id)
		]
		result.add(externalLibs)
		result
	}

	def FileCollection getExternalLibs() {
		project.files(new Callable<FileCollection> () {
			override call() throws Exception {
				val unpackedDependencies = pluginDependencies.externalDependencies.map[
					pluginsCache / id / version
				]
				+
				pluginDependencies.endorsedDependencies.map[
					getIdeaHome / "plugins"/ id
				]
				val dependencyClasses = unpackedDependencies
					.map[
						val classesDir = it / "classes"
						if (classesDir.exists)
							project.files(classesDir)
						else
							project.files
					]
					.reduce[FileCollection a, FileCollection b| a.plus(b)]
				val dependencyLibs = unpackedDependencies
					.map[project.fileTree(it / "lib").include("*.jar") as FileCollection]
					.reduce[FileCollection a, FileCollection b| a.plus(b)]
				#[ideaCoreLibs, dependencyClasses, dependencyLibs].filterNull.reduce[a, b| a.plus(b)]
			}
			
		})
		.builtBy(downloadIdea, downloadPlugins)
	}

	def FileCollection getIdeaCoreLibs() {
		project.fileTree(getIdeaHome + "/lib")
			.builtBy(downloadIdea).include("*.jar") as FileCollection
	}

	def FileCollection getIdeaRunClasspath() {
		ideaCoreLibs.plus(toolsJar)
	}

	def toolsJar() {
		project.files('''«System.getProperty("java.home")»/../lib/tools.jar''')
	}

	def File getIdeaHome() {
		if (ideaHome == null) {
			project.gradle.gradleUserHomeDir / "ideaSDK" / ideaVersion
		} else {
			project.file(ideaHome)
		}
	}

	def File getPluginsCache() {
		project.gradle.gradleUserHomeDir / "ideaPluginDependencies"
	}

	def File getSourcesZip() {
		getIdeaHome / 'sources.zip'
	}

	def File getSandboxDir() {
		project.buildDir / "ideaSandbox"
	}

	def pluginDependencies(Closure<Void> config) {
		project.configure(pluginDependencies as Object, config)
	}

	def pluginRepositories(Closure<Void> config) {
		project.configure(pluginRepositories as Object, config)
	}
}

class IdeaPluginRepositories implements Iterable<IdeaPluginRepository> {
	val repositories = <IdeaPluginRepository>newTreeSet[$0.url.compareTo($1.url)]

	def void url(String url) {
		repositories += new IdeaPluginRepository(url)
	}

	override iterator() {
		repositories.iterator
	}
}

class IdeaPluginDependencies {

	val dependencies = <IdeaPluginDependency>newTreeSet[$0.id.compareTo($1.id)]
	val projectDependencies = <IdeaPluginDependency>newTreeSet[$0.id.compareTo($1.id)]

	def IdeaPluginDependency id(String id) {
		val dependency = new IdeaPluginDependency(id)
		dependencies += dependency
		dependency
	}

	def project(String id) {
		val dependency = new IdeaPluginDependency(id)
		projectDependencies += dependency
		dependency
	}
	
	def getEndorsedDependencies() {
		dependencies.filter[version == null]
	}

	def getExternalDependencies() {
		dependencies.filter[version != null]
	}

	def getProjectDependencies() {
		projectDependencies
	}
}

@Accessors
class IdeaPluginRepository {
	val String url
}

@Accessors
class IdeaPluginDependency {
	val String id
	String version

	def version(String version) {
		this.version = version
	}
}
