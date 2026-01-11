## Custom Components

There are two main types of components in the ui lib. A ```Component``` is mainly just for visuals, with no direct access to current UI events. An ```Actor``` can 
do everything, that a component can do, but witch the additional functionallity of working with current UI events. There are mandatory fields for both Components and 
Actors:

```v
pub interface Component {
	mut:
	from             Vec2
	size             Vec2

	draw(mut ui UI)
}


pub interface Actors {
	mut:
	from             Vec2
	size             Vec2
	user_data        voidptr
	
	event(mut ui UI, event &gg.Event)
	draw(mut ui UI)
}
```

Here is a list of currently implemented/planned UI elements:

#### Components
- Toast
- Text

#### Actors
- Button
- LineEdit

#### Todo
- ColorRect
- ImageRect
- Containers: Scroll, CentreBox, VBox, HBox, VSplit, HSplit
- TextEdit
- IconButton
- CheckBox
- Menu
- TabBar
- ItemDropField
