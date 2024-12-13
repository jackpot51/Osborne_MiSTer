use cosmic::{
    app::{Core, Task},
    executor,
    iced::{ContentFit, Length},
    widget, Element,
};

#[derive(Clone, Debug)]
pub enum Message {}

pub struct App {
    core: Core,
    images: Vec<widget::image::Handle>,
}

impl cosmic::Application for App {
    type Executor = executor::Default;
    type Flags = Vec<widget::image::Handle>;
    type Message = Message;
    const APP_ID: &'static str = "dev.soller.OCC1Viewer";

    fn core(&self) -> &Core {
        &self.core
    }

    fn core_mut(&mut self) -> &mut Core {
        &mut self.core
    }

    fn init(core: Core, images: Self::Flags) -> (Self, Task<Self::Message>) {
        (App { core, images }, Task::none())
    }

    fn update(&mut self, _message: Self::Message) -> Task<Self::Message> {
        Task::none()
    }

    fn view(&self) -> Element<Self::Message> {
        //TODO: show multiple images?
        if let Some(image) = self.images.last() {
            widget::image::viewer(image.clone())
                .content_fit(ContentFit::None)
                .filter_method(widget::image::FilterMethod::Nearest)
                .min_scale(1.0)
                .scale_step(1.0)
                .width(Length::Fill)
                .height(Length::Fill)
                .into()
        } else {
            widget::text("no images found").into()
        }
    }
}
