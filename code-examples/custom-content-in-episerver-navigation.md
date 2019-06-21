# Custom Content In Episerver Navigation

## Descriptor

```csharp
[ServiceConfiguration(typeof(IContentRepositoryDescriptor))]
    public class CommentsPaneDescriptor : ContentRepositoryDescriptorBase
    {
        public static string RepositoryKey { get { return "commets"; } }

        public override string Key { get { return RepositoryKey; } }

        public override string Name { get { return "Comments"; } }

        public override IEnumerable<Type> ContainedTypes
        {
            get
            {
                return new[]
                {
                    typeof(ContentFolder),
                    typeof(Comment)
                };
            }
        }

        public override IEnumerable<Type> CreatableTypes
        {
            get 
            {
                return new[] { typeof(Comment) };
            }
        }

        public override IEnumerable<ContentReference> Roots
        {
            get
            {
                return Enumerable.Empty<ContentReference>();
            }
        }

        public override IEnumerable<Type> MainNavigationTypes
        {
            get
            {
                return new[]
                {
                    typeof(ContentFolder)
                };
            }
        }
    }
```

## ComponentDefinition

```csharp
[Component]
public class CommentsPaneNavigationComponent : ComponentDefinitionBase
{
    public CommentsPaneNavigationComponent() : base("epi-cms.component.SharedBlocks")
    {
        Categories = new[] { "content" };
        Title = "Comments";
        SortOrder = 1000;
        PlugInAreas = new[] { PlugInArea.AssetsDefaultGroup };
        Settings.Add(new Setting("repositoryKey", CommentsPaneDescriptor.RepositoryKey));
    }
}
```

---
[:arrow_left: BACK](../README.md)
```