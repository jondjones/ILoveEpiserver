# Unit Testing A Controller

Lers say we have this controller:  

```csharp
    public class ContentPageController : PageController<ContentPage>
    {
        public ActionResult Index(ContentPage currentPage)
        {
            return View("Index", new ContentPageViewModel(currentPage, EpiServerDependencies));
        }

        public string ReturnCurrentPageType(ContentPage currentPage)
        {
            return currentPage.PageTypeName;
        }

        public ContentAreaItem ReturnContentArea(ContentPage currentPage)
        {
            return currentPage.MainContentArea.Items[0];
        }
    }
```

We can write these tests:.  NOTE this uses *FluentAssertions* and *Moq*

```csharp
[TestFixture]
    public class ContentPageControllerTests
    {
        [TestFixtureSetUp]
        public void Setup()
        {
            var serviceLocator = new Mock<IServiceLocator>();

            var contentRepositoryFactory = new Mock<IContentRepositoryFactory>();
            var linkResolverFactory = new Mock<ILinkResolverFactory>();

            var epiServerDependencies = new EpiServerDependencies(
                contentRepositoryFactory.Object,
                linkResolverFactory.Object);

            serviceLocator.Setup(x => x.GetInstance<IEpiServerDependencies>()).Returns(epiServerDependencies);

            ServiceLocator.SetLocator(serviceLocator.Object);
        }

        [Test]
        public void Will_Controller_Load_With_Dependencies()
        {
            var mockContentPage = new Mock<ContentPage>();

            var contentPageController = new ContentPageController();
            var result = contentPageController.Index(mockContentPage.Object);

            result.Should().NotBeNull();
        }

        [Test]
        public void Show_How_Mock_Setup_Works()
        {
            var testString = Guid.NewGuid().ToString();

            var mockContentPage = new Mock<ContentPage>();
            mockContentPage.Setup(x => x.PageTypeName).Returns(testString);

            var contentPageController = new ContentPageController();
            var result = contentPageController.ReturnCurrentPageType(mockContentPage.Object);

            result.Should().Be(testString);
        }

        [Test]
        public void Adding_To_Content_Area()
        {
            var content = new Mock<IContent>();
            content.Setup(x => x.ContentLink).Returns(new ContentReference(1));

            var contentAreaItemList = new List<ContentAreaItem>
            {
                new ContentAreaItem { ContentLink = content.Object.ContentLink }
            };

            var contentArea = new Mock<ContentArea>();
            contentArea.Setup(x => x.Items).Returns(contentAreaItemList);

            var mockContentPage = new Mock<ContentPage>();
            mockContentPage.Setup(u => u.MainContentArea).Returns(contentArea.Object);

            var controller = new ContentPageController();
            var contentAreaResult = controller.ReturnContentArea(mockContentPage.Object);

            contentAreaResult.ContentLink.Should().Be(new ContentReference(1));
        }
    }
```

---
[:arrow_left: BACK](../README.md)