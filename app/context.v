module app

import app.context { DlRenderContext }

pub fn (mut project Project) make_contexts(context_tags []string) map[string]voidptr {
	mut contexts := map[string]voidptr{}
	for tag in context_tags {
		contexts[tag] = match tag {
			"render_context" { DlRenderContext.new(mut project.ui) }
			else { unsafe { nil } }
		}
	}
	return contexts
}
