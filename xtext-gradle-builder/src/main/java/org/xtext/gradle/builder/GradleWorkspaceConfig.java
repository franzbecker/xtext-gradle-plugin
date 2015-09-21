package org.xtext.gradle.builder;

import java.util.Set;

import org.eclipse.emf.common.util.URI;
import org.eclipse.xtext.util.UriUtil;
import org.eclipse.xtext.workspace.IProjectConfig;
import org.eclipse.xtext.workspace.IWorkspaceConfig;
import org.xtext.gradle.protocol.GradleBuildRequest;

import com.google.common.collect.Sets;

public class GradleWorkspaceConfig implements IWorkspaceConfig {

	private GradleProjectConfig project;

	public GradleWorkspaceConfig(GradleBuildRequest request) {
		this.project = new GradleProjectConfig(request);
	}

	@Override
	public IProjectConfig findProjectContaining(URI member) {
		if (UriUtil.isPrefixOf(project.getPath(), member)) {
			return project;
		}
		return null;
	}

	@Override
	public IProjectConfig findProjectByName(String name) {
		if (project.getName().equals(name)) {
			return project;
		}
		return null;
	}

	@Override
	public Set<? extends IProjectConfig> getProjects() {
		return Sets.newHashSet(project);
	}
}
